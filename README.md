# 🔪 PortKiller

> A lightweight macOS menu bar app to view and kill processes occupying ports. No more `lsof` and `kill` commands in the terminal!

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

![PortKiller Screenshot](docs/screenshot.png)

<!-- TODO: Add screenshot -->

## ✨ Features

- 🎯 **Simple & Fast** - Lives in your menu bar, one click away
- ⌨️ **Keyboard Navigation** - Navigate ports with arrow keys (↑/↓) and kill with Enter
- 🌍 **Multilingual** - Automatic English/French interface based on system language
- 🔍 **Smart Search** - Filter by port number, process name, or PID
- 🏷️ **Clear Port Display** - Port numbers styled as easy-to-read tags
- 🔐 **Safe Kills** - Confirmation for system-critical processes with visual feedback (spinner)
- 📋 **Organized Lists** - Separate system ports (<1024) and user ports (≥1024)
- 🔄 **Manual Refresh** - Update port list on demand
- 🚪 **Quick Exit** - Power button to quit instantly
- 🚫 **No Dock Icon** - Menu bar only, stays out of your way

## 🎬 Demo

<!-- TODO: Add GIF showing the workflow -->

## 🚀 Installation

Choose the installation method that works best for you:

### Option 1: Homebrew (⭐ Recommended)

The easiest way to install and keep PortKiller updated:

```bash
# Add the tap
brew tap cedriceugeni/portkiller

# Install PortKiller
brew install --cask portkiller
```

**Update to latest version:**

```bash
brew upgrade --cask portkiller
```

### Option 2: Download from GitHub Releases

Perfect if you prefer manual installation:

1. Go to [Releases](https://github.com/cedriceugeni/portkiller/releases/latest)
2. Download `PortKiller-v1.0.0.zip` (or latest version)
3. Unzip the file
4. Drag `PortKiller.app` to your `/Applications` folder
5. **First launch:** Right-click the app → **Open** (to bypass Gatekeeper warning)

### Option 3: Build from Source

For developers who want to customize or contribute:

```bash
# Clone the repository
git clone https://github.com/cedriceugeni/portkiller.git
cd portkiller

# Build with Xcode
xcodebuild -workspace PortKiller.xcworkspace \
           -scheme PortKiller \
           -configuration Release \
           build

# The app will be in:
# build/Release/PortKiller.app

# Or open in Xcode to build and run:
open PortKiller.xcworkspace
```

**Requirements for building:**

- macOS 14.0 or later
- Xcode 16.0 or later

---

### ⚠️ First Launch

**macOS will show a security warning** because the app is not signed or notarized. This is normal and expected for open-source apps distributed outside the Mac App Store.

**To open the app:**

1. Right-click (or Control-click) on `PortKiller.app`
2. Select **Open** from the menu
3. Click **Open** in the security dialog

**Or use Terminal:**

```bash
xattr -cr /Applications/PortKiller.app
open /Applications/PortKiller.app
```

After the first launch, you can open PortKiller normally from Spotlight or Applications.

## 📖 Usage

1. Click the menu bar icon to open PortKiller
2. Browse the list of occupied ports
3. Search for specific ports or processes
4. **Kill a process:**
   - Hover over a row and click **Stop**, or
   - Use **arrow keys** (↑/↓) to navigate and **Enter** to kill
5. Click the refresh button to update the list
6. Click the **power icon** at bottom-right to quit

### Keyboard Shortcuts

- **↑/↓** - Navigate through port list
- **Enter** - Kill selected process
- **Type** - Search/filter ports in real-time

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
