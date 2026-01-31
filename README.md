# 🔪 PortKiller

> A lightweight macOS menu bar app to view and kill processes occupying ports. No more `lsof` and `kill` commands in the terminal!

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

![PortKiller Screenshot](docs/screenshot.png)
<!-- TODO: Add screenshot -->

## ✨ Features

- 🎯 **Simple & Fast** - Lives in your menu bar, one click away
- 🔍 **Smart Search** - Filter by port number, process name, or PID
- 🏷️ **Clear Port Display** - Port numbers styled as easy-to-read tags
- 🔐 **Safe Kills** - Confirmation for system-critical processes
- 📋 **Organized Lists** - Separate system ports (<1024) and user ports (≥1024)
- 🔄 **Manual Refresh** - Update port list on demand
- 🚫 **No Dock Icon** - Menu bar only, stays out of your way

## 🎬 Demo

<!-- TODO: Add GIF showing the workflow -->

## 🚀 Installation

### Via Homebrew (Recommended)

```bash
brew install --cask cedriceugeni/portkiller/portkiller
```

### Manual Installation

1. Download the latest release from [Releases](https://github.com/cedriceugeni/portkiller/releases)
2. Unzip and move `PortKiller.app` to `/Applications`
3. Right-click → Open (first time only, to bypass Gatekeeper)

**Note**: macOS will warn about an unsigned app. This is normal - the app is open source and not notarized.

## 🛠️ Build from Source

```bash
# Clone the repository
git clone https://github.com/cedriceugeni/portkiller.git
cd portkiller

# Build with Xcode
xcodebuild -workspace PortKiller.xcworkspace \
           -scheme PortKiller \
           -configuration Release \
           build

# App will be in: build/Release/PortKiller.app
```

### Requirements
- macOS 14.0 or later
- Xcode 16.0 or later

## 📖 Usage

1. Click the menu bar icon to open PortKiller
2. Browse the list of occupied ports
3. Search for specific ports or processes
4. Hover over a row and click **Stop** to kill the process
5. Click the refresh button to update the list

### Permissions

PortKiller requires permission to execute system commands (`lsof` and `kill`). The app is **not sandboxed** to allow these operations. All code is open source for transparency.

## 🏗️ Architecture

Built with modern Swift and SwiftUI using a clean workspace + Swift Package architecture:

```
├── PortKiller.xcworkspace/          # Main workspace
├── PortKiller/                      # App shell (minimal)
│   ├── AppDelegate.swift           # Menu bar setup
│   └── PortKillerApp.swift         # App entry point
└── PortKillerPackage/               # Feature package
    └── Sources/PortKillerFeature/
        ├── Services/
        │   ├── PortScanner.swift   # lsof execution & parsing
        │   └── ProcessKiller.swift # Process termination
        ├── Views/
        │   ├── PopoverView.swift   # Main UI
        │   └── PortRowView.swift   # Port list item
        └── Models/
            └── PortInfo.swift      # Data model
```

### Key Technologies
- **SwiftUI** for UI
- **NSStatusBar** for menu bar integration
- **Process API** for executing `lsof` and `kill`
- **Swift 6** concurrency with async/await

## 🤝 Contributing

Contributions are welcome! Feel free to:
- 🐛 Report bugs
- 💡 Suggest features
- 🔧 Submit pull requests

## ⚠️ Disclaimer

This app executes system commands with elevated privileges when needed. Use with caution when killing processes. Critical system processes are protected, but you can still break things if you're not careful.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built because running `lsof -iTCP -sTCP:LISTEN -n -P` and `kill -9` every time got old real fast.

---

**Made with ❤️ and Swift** | [Report an Issue](https://github.com/cedriceugeni/portkiller/issues)
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
    }
}
```

### Asset Management
- **App-Level Assets**: `PortKiller/Assets.xcassets/` (app icon with multiple sizes, accent color)
- **Feature Assets**: Add `Resources/` folder to SPM package if needed

### SPM Package Resources
To include assets in your feature package:
```swift
.target(
    name: "PortKillerFeature",
    dependencies: [],
    resources: [.process("Resources")]
)
```

## Notes

### Generated with XcodeBuildMCP
This project was scaffolded using [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP), which provides tools for AI-assisted macOS development workflows.