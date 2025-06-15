# Clipboard History App - Release Notes

## Version 1.0 - Latest Update

### 🎯 New Features

#### Direct Hotkey Access (⌘⇧1-6)
- **Instant Item Access**: Press ⌘⇧1 through ⌘⇧6 to copy items directly
- **No Popup Needed**: Maximum speed for frequently used items
- **Visual Indices**: All items now show numbers (1, 2, 3, etc.) for easy identification
- **Menu Shortcuts**: First 6 menu items also show ⌘⇧1-6 keyboard shortcuts

#### Improved Full Text Viewing
- **⌘+Click to View Full Text**: Much more intuitive than double-click
- **Scrollable Text Dialog**: Properly displays long clipboard content
- **Fixed Text Visibility**: Text now displays correctly in the full text viewer
- **Safe Window Management**: No more crashes when closing dialogs

#### Enhanced User Experience
- **Better Interaction Pattern**: 
  - Click: Copy item
  - ⌘+Click: View full text (NEW!)
  - Double-click: View full text (fallback)
  - Right-click: Context menu with options
- **Clear Instructions**: Visual guidance in popup and menu bar
- **Professional Icons**: Custom clipboard icon in menu bar and app bundle

#### Customizable Settings
- **Popup Item Count**: Configure 1-20 items in popup (Settings menu)
- **Persistent Configuration**: Settings saved between app launches

### 🔧 Technical Improvements

#### Code Quality & Architecture
- **Modular Design**: Separated core logic into ClipboardHistoryCore library
- **Comprehensive Testing**: 61 unit tests with 100% pass rate
- **SwiftLint Integration**: Clean, consistent code style
- **Memory Management**: Fixed crashes and improved stability

#### Performance & Reliability
- **Release Build**: Optimized for performance
- **Crash Prevention**: Robust error handling and memory management
- **Proper Cleanup**: Safe window and resource management

### 🎨 UI/UX Enhancements
- **Modern Menu Bar Icon**: System-style clipboard symbol with fallback
- **Professional App Icon**: High-quality icon set (16x16 to 1024x1024)
- **Improved Popup Design**: Better layout and visual feedback
- **Accessible Instructions**: Clear guidance for all interaction methods

### 🐛 Bug Fixes
- Fixed crashes when closing full text dialog
- Fixed text not displaying in scrollable viewer
- Fixed memory management issues
- Fixed window delegate cleanup
- Improved hotkey registration reliability

### 📋 Current Features
- **Clipboard Monitoring**: Automatic capture of clipboard changes
- **History Management**: Up to 20 items with persistent storage
- **Quick Access**: ⌘⇧C hotkey for instant popup
- **Multiple Access Methods**: Menu bar, hotkey popup, and context menus
- **Text Processing**: Smart cleaning and truncation for display
- **Delete & Clear**: Individual item deletion and full history clearing

### 🚀 Installation
The app is now updated in `/Applications/ClipboardHistoryApp.app` with all the latest improvements!

---
*Built with Swift, AppKit, and attention to detail.* 