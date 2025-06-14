# Clipboard History App

A macOS menu bar app that tracks your clipboard history and allows you to easily access previously copied items.

## Features

- 📋 Tracks up to 20 recent clipboard items
- 🔍 Quick access via menu bar icon
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

1. After launching, you'll see a scissors icon in your menu bar
2. Copy any text to your clipboard - it will be automatically tracked
3. Click the menu bar icon to see your clipboard history
4. Click any item to copy it back to your clipboard
5. Use "Clear History" to remove all tracked items
6. Use "Quit" to exit the app

## Development

The app consists of two main files:

- `main.swift` - App entry point and menu bar setup
- `ClipboardManager.swift` - Clipboard monitoring and history management

## Privacy

This app only accesses clipboard content when changes are detected. No data is sent to external servers or stored permanently on disk. 