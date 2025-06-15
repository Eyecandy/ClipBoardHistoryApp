# Clipboard History App

A modern, professional macOS menu bar app that tracks your clipboard history and provides lightning-fast access to previously copied items with comprehensive testing, clean architecture, and advanced management features.

## ✨ Features

### Core Functionality
- 📋 **Tracks up to 20 recent clipboard items** with automatic persistence
- 🔍 **Professional menu bar interface** with numbered items and keyboard shortcuts
- ⚡ **Global hotkey support (⌘⇧C)** - Shows top items in a floating popup near your cursor
- 🎯 **Direct item access (⌘⇧1-6)** - Copy clipboard items 1-6 instantly without popup
- 🎛️ **Customizable popup size** - Configure 1-20 items to show in popup (default: 5)
- 💾 **Persistent history** - Items are saved and restored between app sessions
- 🧹 **Individual item deletion** and complete history clearing

### Advanced Interactions
- 🖱️ **Multiple interaction methods:**
  - **Single click**: Copy item to clipboard
  - **⌘+Click**: View full text content (primary method)
  - **Double-click**: View full text content (fallback)
  - **Right-click**: Context menu with copy, view, and delete options
- 👀 **Professional full text viewer** with scrollable content and character count
- 🎯 **Visual indexing** - All items show numbers (1, 2, 3...) for easy identification
- ⚡ **Smart auto-hide** - Popup pauses when mouse hovers, resumes when you move away
- 🎨 **Focus preservation** - Returns cursor to original app after selection

### Professional Polish
- 🎯 **Menu bar only** (no dock icon) - lightweight and unobtrusive
- 🎨 **Custom icons** - Professional clipboard symbol with high-quality app icons
- 🔄 **Smart text handling** - Multi-line text is properly cleaned for display
- ⚡ **Lightweight and fast** with modern Swift architecture
- 🛡️ **Secure** - No sensitive data logging, local-only storage

## 🔧 Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)

## 🚀 Building and Running

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

## 📖 Usage

### Menu Bar Access
1. After launching, you'll see a clipboard icon in your menu bar
2. Copy any text to your clipboard - it will be automatically tracked and saved
3. Click the menu bar icon to see your clipboard history with numbered items
4. **First 6 items show ⌘⌥1-6 shortcuts** for direct access
5. Each clipboard item has three options:
   - **Copy**: Copy the item back to your clipboard
   - **View Full Text**: See the complete content in a resizable window
   - **Delete**: Remove this specific item from history
6. Use "Clear History" to remove all tracked items
7. Configure popup item count in Settings → Popup Items (1-20 items)

### Global Hotkeys

#### Quick Popup (⌘⇧C)
1. Press **⌘⇧C** (Cmd+Shift+C) anywhere on your Mac
2. A floating popup appears near your cursor showing recent clipboard items
3. **Interaction methods:**
   - **Click**: Copy item to clipboard
   - **⌘+Click**: View full text content (recommended)
   - **Double-click**: View full text content (fallback)
   - **Right-click**: Show context menu with copy, view, and delete options
4. The popup automatically hides after 10 seconds
5. **Smart behavior**: Pauses auto-hide when mouse hovers over items
6. Shows specific hotkey for each item (e.g., "⌘⌥1: direct copy")

#### Direct Item Access (⌘⌥1-6)
1. Press **⌘⌥1** through **⌘⌥6** anywhere on your Mac
2. **Instantly copies** the corresponding clipboard item (1st, 2nd, 3rd, etc.)
3. **No popup needed** - immediate clipboard access for maximum speed
4. Only works if the item exists (e.g., ⌘⌥3 only works if you have 3+ items)
5. Perfect for frequently accessed items
6. **Silent operation** - no visual feedback for security

### Settings & Customization
1. **Popup Item Count**: Access via menu bar → Settings → Popup Items
   - Choose from 1 to 20 items to show in the popup
   - Default is 5 items for optimal balance
   - Setting is saved and persists between app sessions
2. **Clear History**: Remove all tracked clipboard items
3. **Visual feedback**: Current setting highlighted in menu

### Copy-Only Workflow
- This app uses a **copy-only** approach for simplicity and reliability
- When you select an item (from menu or popup), it's copied to your clipboard
- You then paste it manually wherever needed using **⌘V**
- **No accessibility permissions required**
- Works consistently across all applications
- **Focus preservation** - cursor returns to original app position

## 🏗️ Architecture & Development

### Clean Architecture
The app follows modern Swift architecture with separated concerns:

- **`ClipboardHistoryCore`** - Core business logic library
  - **`ClipboardManager.swift`** - Clipboard monitoring, history management, and persistence
  - **`HotkeyManager.swift`** - Global hotkey registration using Carbon API (7 total hotkeys)
  - **`ClipboardPopup.swift`** - Floating popup window with rich interaction support
  - **`StringExtensions.swift`** - Text processing utilities
- **`ClipboardHistoryApp`** - Main executable
  - **`main.swift`** - App entry point, coordination, and UI management

### Quality Assurance
- **68 comprehensive unit tests** with 100% pass rate
- **4 test suites** covering all major components:
  - ClipboardManagerTests (24 tests) - History management, persistence, direct hotkey support
  - HotkeyManagerTests (13 tests) - Hotkey registration, delegate patterns, direct hotkeys  
  - ClipboardPopupTests (13 tests) - Popup behavior, mouse interaction, display logic
  - StringExtensionTests (18 tests) - Text cleaning and truncation utilities
- **Zero build warnings** in both debug and release configurations
- **Memory leak prevention** with proper cleanup and weak references

### Technical Features
- **Persistent Storage**: Uses UserDefaults for reliable history persistence
- **Memory Efficient**: Automatic cleanup of old items (20 item limit)
- **Thread Safe**: Proper main queue dispatching for UI updates
- **Modern Swift**: Uses latest Swift patterns and best practices
- **No External Dependencies**: Pure Swift and AppKit implementation
- **Global Hotkeys**: Carbon API integration for system-wide hotkey support
- **Professional Error Handling**: Comprehensive bounds checking and safe unwrapping
- **Security-First**: No sensitive data logging, secure clipboard handling

## 🔒 Privacy & Security

- ✅ **Local Only**: No data is sent to external servers
- ✅ **No Accessibility Permissions**: Copy-only approach eliminates permission requirements
- ✅ **User Control**: Easy deletion of specific items or complete history
- ✅ **Transparent**: Open source with clear, readable code
- ✅ **Minimal Footprint**: Only accesses clipboard when changes are detected
- ✅ **Secure Logging**: No clipboard content logged in release builds
- ✅ **Safe Memory Management**: Proper cleanup prevents data leaks

## 📦 Installation

### From Source
Follow the build instructions above to create your own app bundle.

### Pre-built App (if available)
Copy the `ClipboardHistoryApp.app` to your `/Applications/` folder for system-wide access.

## 🧪 Testing

Run the comprehensive test suite:

```bash
swift test
```

All 68 tests should pass, covering:
- Clipboard history management
- Hotkey registration and handling
- Popup display and interaction
- Text processing and cleaning
- Direct hotkey functionality
- Memory management and cleanup
- Settings persistence

## 🤝 Contributing

This project maintains high code quality standards:
- All code must pass existing tests
- New features should include comprehensive tests
- Follow Swift best practices and conventions
- Ensure zero build warnings
- Maintain security-first approach

---

*Built with Swift, AppKit, comprehensive testing, and attention to detail.* 