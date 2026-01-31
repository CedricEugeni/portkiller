# PortKiller - AI Agent Guidelines

## Architecture Overview

PortKiller is a **menubar-only macOS app** (no dock icon) using a **workspace + SPM package** separation pattern for clean architecture.

### 3-Layer Structure

1. **App Shell** (`PortKiller/`): Minimal app lifecycle code - `AppDelegate.swift` creates the menubar item and popover, `PortKillerApp.swift` is the entry point
2. **Feature Package** (`PortKillerPackage/Sources/PortKillerFeature/`): All business logic, views, and services
3. **Xcode Workspace** (`PortKiller.xcworkspace`): Coordinates the app and package

### Key Design Decisions

- **Why SPM package?** Enforces clean boundaries and enables independent testing
- **Why menubar-only?** Set via `INFOPLIST_KEY_LSUIElement = YES` in `Config/Shared.xcconfig`
- **Why disable sandbox?** App needs to execute `/usr/sbin/lsof` and `kill` commands directly - see `Config/PortKiller.entitlements` where `com.apple.security.app-sandbox` is `false`

## Critical Workflows

### Building and Running

```bash
# ALWAYS kill existing app first to avoid stale processes
killall PortKiller 2>/dev/null || true

# Build from workspace (NOT project)
xcodebuild -workspace PortKiller.xcworkspace -scheme PortKiller -configuration Debug build

# Launch the built app
open build/Debug/PortKiller.app
```

**Note:** Build output is in `build/Debug/` (custom DerivedData path configured in Xcode)

### Adding Features

1. Add files to `PortKillerPackage/Sources/PortKillerFeature/` - Xcode 16's **buildable folders** auto-detect them
2. Make types `public` if exposed to app target (e.g., `public struct PopoverView: View`)
3. Add `public init() {}` for public types
4. Xcode automatically includes new files - no manual project updates needed

### Testing

- **Unit tests**: `PortKillerPackage/Tests/PortKillerFeatureTests/` using Swift Testing framework
- **UI tests**: `PortKillerUITests/` using XCUITest
- Run via `PortKiller.xctestplan` or `xcodebuild test -workspace PortKiller.xcworkspace -scheme PortKiller`

## Code Organization Patterns

### Service Layer (`Services/`)

- `PortScanner`: Uses `/usr/sbin/lsof -iTCP -sTCP:LISTEN -n -P` to find listening ports
  - Parses lsof output line-by-line, splitting by whitespace
  - Expects format: `COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME`
  - Extracts port from `NAME` column (format: `*:PORT` or `ADDRESS:PORT`)
  - Exit code 1 from lsof is normal (no ports found), only fail on other codes
- `ProcessKiller`: Executes `kill -9` directly, escalates to `osascript` with admin privileges if needed
- Services are **non-sandboxed by necessity** - this is intentional

### View Layer (`Views/`)

- `PopoverView`: Main interface shown in menubar popover (400x500px)
  - Implements keyboard navigation with `@FocusState` and `.onKeyPress()`
  - Tracks `selectedPortId` for arrow key navigation
  - Tracks `killingPortId` to show spinner during process termination
  - Uses `ScrollViewReader` to auto-scroll to selected port
- `PortRowView`: Individual port list item
  - Accepts `isSelected` and `isKilling` parameters
  - Shows Stop button on hover/selection, spinner when killing
- All views use SwiftUI and maintain `@Published` state via `@MainActor` view models

### Helpers Layer (`Helpers/`)

- `LocalizedString.swift`: Custom localization helper
  - `String.moduleLocalized(_:)` reads `Locale.preferredLanguages`
  - Manually loads correct `.lproj` bundle (e.g., fr.lproj, en.lproj)
  - Required because `String(localized:, bundle:)` doesn't respect system language
  - Works in both Debug and Release builds

### Resources (`Resources/`)

- `Localizable.xcstrings`: String Catalog with English/French translations
  - Contains all UI strings (search placeholders, button labels, alerts)
  - Compiled to `.lproj` bundles automatically by Xcode
  - Must be declared in `Package.swift` with `resources: [.process("Resources")]`

### Models (`Models/`)

- `PortInfo`: Parsed lsof output with `isSystemPort` (port < 1024) classification
- All models conform to `Identifiable` and `Equatable` for SwiftUI

## Project-Specific Conventions

### Public API Pattern

```swift
// REQUIRED for types used by app target
public struct MyView: View {
    public init() {}  // ALWAYS add public init

    public var body: some View {
        // implementation
    }
}
```

### Keyboard Navigation Pattern

```swift
// Use @FocusState for TextField, @State for selection
@FocusState private var isSearchFocused: Bool
@State private var selectedPortId: UUID?

// Capture key presses at view level
.onKeyPress(.upArrow) {
    navigateUp()
    return .handled
}
.onKeyPress(.downArrow) {
    navigateDown()
    return .handled
}
.onKeyPress(.return) {
    if let selectedId = selectedPortId {
        performAction(for: selectedId)
        return .handled
    }
    return .ignored
}

// Use ScrollViewReader for auto-scroll
ScrollViewReader { scrollProxy in
    // ... ForEach with .id(item.id)
}
.onChange(of: selectedPortId) { _, newId in
    if let newId = newId {
        withAnimation {
            scrollProxy.scrollTo(newId, anchor: .center)
        }
    }
}
```

### Localization Pattern

```swift
// Use custom helper for SPM module bundles
Text(String.moduleLocalized("My String"))
TextField(String.moduleLocalized("Placeholder"), text: $text)

// Helper function in Helpers/LocalizedString.swift
extension String {
    static func moduleLocalized(_ key: String) -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2))

        if let bundlePath = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }
}
```

### Loading State Pattern

```swift
// Track operation in progress with state
@State private var killingPortId: UUID?

// Set before async operation
await MainActor.run {
    killingPortId = port.id
}

// Pass to child view
PortRowView(
    port: port,
    isKilling: killingPortId == port.id
) { /* action */ }

// Child shows spinner when isKilling == true
if isKilling {
    ProgressView().scaleEffect(0.7)
} else {
    Button("Stop") { /* action */ }
}

// Clear after operation completes
await MainActor.run {
    killingPortId = nil
}
```

### Async/Await for Process Execution

```swift
// Standard pattern: Process wrapper with async/await
private func executeCommand() async throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/path/to/command")
    process.arguments = ["-flag"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    try process.run()
    process.waitUntilExit()

    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}
```

### Configuration via XCConfig Files

- Modify `Config/Shared.xcconfig` for bundle ID, version, deployment target
- Modify `Config/PortKiller.entitlements` for sandbox and capabilities
- **Never hardcode** these values in code or pbxproj

### Menubar Integration (AppDelegate Pattern)

- `NSApplicationDelegateAdaptor` in `PortKillerApp.swift` bridges to `AppDelegate`
- Status bar item created in `applicationDidFinishLaunching(_:)`
- Popover shows/hides with `NSPopover.transient` behavior

## Common Pitfalls

1. **Forgetting `public` access**: Types in SPM package need explicit `public` to be visible to app target
2. **Wrong build command**: Must use `-workspace`, never `-project` alone
3. **File not appearing**: Wait 2-3 seconds after creating file for Xcode to auto-detect (buildable folders)
4. **App not updating**: Always `killall PortKiller` before rebuilding to avoid stale processes
5. **Process execution fails**: Check entitlements - sandbox must be disabled for system commands
6. **Localization not working**: `String(localized:, bundle: .module)` doesn't respect system language - use custom `String.moduleLocalized()` helper instead
7. **Keyboard events not captured**: `.onKeyPress()` must be at view level, not on TextField - keep focus management separate from key handling

## External Dependencies

- **Platform**: macOS 14.0+ (see `MACOSX_DEPLOYMENT_TARGET` in `Config/Shared.xcconfig`)
- **System Commands**: `/usr/sbin/lsof`, `/bin/kill`, `/usr/bin/osascript`
- **Swift Package Manager**: No external packages currently - add via `PortKillerPackage/Package.swift`

## Documentation Maintenance

**CRITICAL: When implementing new features, you MUST update:**

1. **This file** (`.github/copilot-instructions.md`):
   - Add new architectural patterns or conventions
   - Document new services, models, or views
   - Update workflows if build/test process changes
   - Add new pitfalls discovered during development

2. **Repository README** (`README.md`):
   - Update feature descriptions
   - Add new usage examples
   - Document new configuration options
   - Keep architecture diagrams current

**Why?** AI agents rely on these documents for context. Outdated docs lead to incorrect assumptions and wasted time.

## When to Ask User

- Adding new entitlements beyond file access (network, camera, etc.)
- Changing bundle identifier or app name (affects keychain, preferences)
- Introducing external SPM dependencies
- Modifying the menubar/dock behavior (`LSUIElement`)
