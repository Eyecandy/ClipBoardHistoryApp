# Clipboard History App

A macOS menu bar app that tracks your clipboard history and allows you to easily access previously copied items.

## Features

- 📋 Tracks up to 20 recent clipboard items
- 🔍 Quick access via menu bar icon
- ⚡ **Global hotkey support (⌘⇧V)** - Shows top 3 items in a floating popup
- 🖱️ **Right-click to paste** - Right-click any item in the popup to paste it instantly
- 🧹 Clear history option
- 🎯 Menu bar only (no dock icon)
- ⚡ Lightweight and fast

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)

## Building and Running

### Using Swift Package Manager (Recommended)

1. Open Terminal and navigate to the project directory
2. Build the project:
   ```bash
   swift build -c release
   ```
3. Run the app:
   ```bash
   swift run
   ```

### Using Xcode

1. Open Terminal and navigate to the project directory
2. Generate Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```
3. Open `ClipboardHistoryApp.xcodeproj` in Xcode
4. Build and run (⌘+R)

## Usage

### Menu Bar Access
1. After launching, you'll see a scissors icon in your menu bar
2. Copy any text to your clipboard - it will be automatically tracked
3. Click the menu bar icon to see your clipboard history
4. Click any item to copy it back to your clipboard
5. Use "Clear History" to remove all tracked items
6. Use "Quit" to exit the app

### Global Hotkey (⌘⇧V)
1. Press **⌘⇧V** (Cmd+Shift+V) anywhere on your Mac
2. A floating popup will appear near your cursor showing the **3 most recent** clipboard items
3. **Right-click** on any item to instantly paste it at your current cursor position
4. The popup will automatically disappear after 5 seconds or when you click elsewhere
5. Hover over items to see them highlighted

## Development

The app consists of four main files:

- `main.swift` - App entry point and coordination
- `ClipboardManager.swift` - Clipboard monitoring and history management
- `HotkeyManager.swift` - Global hotkey registration and handling (⌘⇧V)
- `ClipboardPopup.swift` - Floating popup window with clipboard items

## Privacy

This app only accesses clipboard content when changes are detected. No data is sent to external servers or stored permanently on disk. The global hotkey monitoring is handled locally by the system. 