# Clipboard History App

A modern macOS menu bar app that tracks your clipboard history and provides easy access to previously copied items with persistent storage and advanced management features.

## Features

- 📋 **Tracks up to 20 recent clipboard items** with automatic persistence
- 🔍 **Quick access via menu bar icon** with professional submenus for each item
- ⚡ **Global hotkey support (⌘⇧C)** - Shows top items in a floating popup near your cursor
- 🎯 **Direct item access (⌘⇧1-6)** - Copy clipboard items 1-6 instantly without popup
- 🎛️ **Customizable popup size** - Configure 1-20 items to show in popup (default: 3)
- 🖱️ **Multiple interaction methods:**
  - **Single click**: Copy item to clipboard
  - **Double-click**: View full text content
  - **Right-click**: Context menu with copy, view, and delete options
- 🗑️ **Delete specific items** from history
- 👀 **Full text viewing** for long clipboard content with resizable dialog
- 💾 **Persistent history** - Items are saved and restored between app sessions
- 🧹 **Clear all history** option
- 🎯 **Menu bar only** (no dock icon) - lightweight and unobtrusive
- ⚡ **Lightweight and fast** with modern Swift architecture
- 🔄 **Smart text handling** - Multi-line text is properly cleaned for display

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

### Using the Build Script

The project includes a convenient build script that creates a proper app bundle:

```bash
./build_and_run.sh
```

This script:
- Builds the project for release
- Creates a proper macOS app bundle
- Code signs the app for consistent permissions
- Runs the app with persistent settings

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
1. After launching, you'll see a scissors icon (✂️) in your menu bar
2. Copy any text to your clipboard - it will be automatically tracked and saved
3. Click the menu bar icon to see your clipboard history with professional submenus
4. Each clipboard item has three options:
   - **Copy**: Copy the item back to your clipboard
   - **View Full Text**: See the complete content in a resizable window
   - **Delete**: Remove this specific item from history
5. Use "Clear History" to remove all tracked items
6. Use "Quit" to exit the app (history is automatically saved)

### Global Hotkeys

#### Quick Popup (⌘⇧C)
1. Press **⌘⇧C** (Cmd+Shift+C) anywhere on your Mac
2. A floating popup appears near your cursor showing the **most recent** clipboard items
3. **Interaction methods:**
   - **Click**: Copy item to clipboard
   - **⌘+Click**: View full text content
   - **Right-click**: Show context menu with copy, view, and delete options
4. The popup automatically disappears after 10 seconds or when you interact with it
5. Hover over items to see them highlighted

#### Direct Item Access (⌘⇧1-6)
1. Press **⌘⇧1** through **⌘⇧6** anywhere on your Mac
2. **Instantly copies** the corresponding clipboard item (1st, 2nd, 3rd, etc.)
3. **No popup needed** - immediate clipboard access for maximum speed
4. Only works if the item exists (e.g., ⌘⇧3 only works if you have 3+ items)
5. Perfect for frequently accessed items

### Settings & Customization
1. **Popup Item Count**: Access via menu bar → Settings → Popup Items
   - Choose from 1 to 20 items to show in the popup
   - Default is 3 items for quick access
   - Setting is saved and persists between app sessions
2. **Clear History**: Remove all tracked clipboard items
3. The number of items shown adapts dynamically to your preference

### Copy-Only Workflow
- This app uses a **copy-only** approach for simplicity and reliability
- When you select an item (from menu or popup), it's copied to your clipboard
- You then paste it manually wherever needed using **⌘V**
- No accessibility permissions required
- Works consistently across all applications

## Development

The app follows modern Swift architecture with four main components:

- **`main.swift`** - App entry point, coordination, and UI management
- **`ClipboardManager.swift`** - Clipboard monitoring, history management, and persistence
- **`HotkeyManager.swift`** - Global hotkey registration using Carbon API (⌘⇧C)
- **`ClipboardPopup.swift`** - Floating popup window with rich interaction support

## Technical Features

- **Persistent Storage**: Uses UserDefaults for reliable history persistence
- **Memory Efficient**: Automatic cleanup of old items (20 item limit)
- **Thread Safe**: Proper main queue dispatching for UI updates
- **Modern Swift**: Uses latest Swift patterns and best practices
- **No External Dependencies**: Pure Swift and AppKit implementation
- **Global Hotkeys**: Carbon API integration for system-wide hotkey support

## Privacy & Security

- ✅ **Local Only**: No data is sent to external servers
- ✅ **No Accessibility Permissions**: Copy-only approach eliminates permission requirements
- ✅ **User Control**: Easy deletion of specific items or complete history
- ✅ **Transparent**: Open source with clear, readable code
- ✅ **Minimal Footprint**: Only accesses clipboard when changes are detected

## Installation

### From Source
Follow the build instructions above to create your own app bundle.

### Pre-built App (if available)
Copy the `ClipboardHistoryApp.app` to your `/Applications/` folder for system-wide access. 