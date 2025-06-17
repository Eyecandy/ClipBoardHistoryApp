# Clipboard History App

A powerful macOS menu bar app that revolutionizes clipboard management with auto-paste functionality, pinned items, configurable hotkeys, and intelligent workflow features.

## ✨ Key Features

### 🚀 **Instant Paste Workflow**
- **⌘⌥1-6: Instant copy & paste** - Items are copied AND automatically pasted
- **🔮 Preview on Hold** - Hold ⌘⌥1-6 for 0.5s to see preview before pasting
- **Click to copy** - Single click in popup copies item to clipboard  
- **Hover+⌘V to paste** - Hover over item, then press ⌘V to paste
- **Focus preservation** - Maintains your cursor position in original app

### 📌 **Pinned Items System**
- **Pin frequently used items** for permanent access
- **⌘⇧P: Show pinned items** popup (configurable hotkey)
- **Mode switching** - ⌘⌥1-6 picks from current mode (history or pinned)
- **Persistent pinning** - Pinned items survive app restarts

### ⚙️ **Fully Configurable Hotkeys**
- **All hotkeys customizable** with user-friendly names
- **Settings window** for easy hotkey configuration  
- **Reset individual** or **reset all** hotkey options
- **Live preview** of current key combinations

### 🎯 **Smart Visual Feedback**
- **● Mint green dot** - Current clipboard item indicator (what's currently copied)
- **Collapsible sections** - Click ▶︎/▼ to expand/collapse history and pinned items
- **Smart scrolling** - "More..." sections for 10+ items with hover access
- **Visual mode indicators** (📌 Pinned, 📋 History)
- **Enhanced hover effects** with clear interaction cues
- **Animated preview window** for hotkey previews

### ⏱️ **Configurable Popup Behavior**
- **Auto-hide timeout**: 0-5 minutes (0 = never hide)
- **Smart timeout display**: Shows minutes and seconds
- **Mouse-aware hiding** - Pauses when hovering
- **No focus stealing** - Popup doesn't interrupt your work

## 🔧 Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)

## 🚀 Quick Start

### Build & Run
```bash
swift build -c release && swift run
```

### Using Build Script
```bash
./build_and_run.sh
```

## 📖 Usage Guide

### 🔥 **Power User Workflow**

#### **Instant Paste (Fastest)**
- **⌘⌥1**: Copy & paste most recent item instantly
- **⌘⌥2-6**: Copy & paste items 2-6 instantly
- **Hold ⌘⌥1-6**: Preview window after 0.5s, auto-paste after 2.5s
- Perfect for repetitive workflows

#### **Popup Selection (Visual)**
- **⌘⇧C**: Show clipboard history popup
- **⌘⇧P**: Show pinned items popup  
- **Click**: Copy item to clipboard
- **Hover+⌘V**: Copy on hover, paste with ⌘V
- **⌘+Click**: View full text

#### **Menu Bar Access (Complete)**
- Click clipboard icon for full menu
- **● Mint green dot** shows current clipboard item
- **📌 Pinned Items** section (collapsible, max 10 visible)
- **📋 Recent History** section (collapsible, max 10 visible)
- **Smart "More..." submenus** for items beyond limit
- **Toggle collapse/expand** without losing menu focus

### ⚙️ **Customization**

#### **Hotkey Configuration**
1. Menu Bar → Settings → Configure Hotkeys
2. Click any hotkey combination to change
3. Use "Reset" or "Reset All" as needed
4. All hotkeys have descriptive names

#### **Popup Settings**
- **Display Items**: 1-20 items in popup
- **Auto-Hide Timeout**: 0-5 minutes
  - 0 = Never auto-hide
  - Shows as "2m 30s" for times ≥60 seconds

#### **Pin Management**
- **Right-click** any item → "Pin Item"
- **Pinned items menu** for bulk management
- **Mode switching** - ⌘⌥1-6 uses current mode

### 🎯 **Interaction Methods**

| Action | History Popup | Pinned Popup | Menu Items |
|--------|---------------|--------------|------------|
| **Click** | Copy to clipboard | Copy to clipboard | Copy to clipboard |
| **Hover+⌘V** | Copy then paste | Copy then paste | - |
| **⌘+Click** | View full text | View full text | View full text |
| **Right-click** | Context menu | Context menu | Submenu |
| **⌘⌥1-6** | Copy & paste item 1-6 | Copy & paste item 1-6 | - |
| **Hold ⌘⌥1-6** | Preview → auto-paste | Preview → auto-paste | - |

### 🔄 **Workflow Examples**

#### **Code Snippets (Pinned Items)**
1. Pin frequently used code snippets
2. Press **⌘⇧P** to show pinned items
3. **⌘⌥1** to instantly paste most-used snippet

#### **Research & Writing (History)**
1. Copy quotes, references, notes
2. Press **⌘⇧C** to see recent items
3. **Hover** over item, press **⌘V** to paste

#### **Mixed Workflow**
1. Copy something → automatically in history
2. **Pin** important items for later
3. Use **⌘⌥1-6** to access either mode

## 🏗️ Technical Architecture

### Core Components
- **`ClipboardManager`** - History, pinning, auto-paste, settings
- **`HotkeyManager`** - Configurable hotkeys, mode switching  
- **`HotkeySettings`** - Persistent hotkey configuration
- **`ClipboardPopup`** - Enhanced popup with highlighting & timeout
- **`main.swift`** - UI coordination, settings windows

### New Features Added
- ✅ **Auto-paste simulation** using CGEvent for ⌘V
- ✅ **Pinned items storage** with UserDefaults persistence
- ✅ **Configurable hotkeys** with HotkeySettings class
- ✅ **Current item tracking** and visual highlighting
- ✅ **Timeout configuration** with smart display formatting
- ✅ **Mode switching** between history and pinned items
- ✅ **Focus preservation** using NSRunningApplication
- ✅ **Enhanced popup interaction** without focus stealing

## 🔒 Privacy & Security

- **✅ Local-only storage** - No cloud sync or external servers
- **✅ No accessibility permissions** required
- **✅ Secure hotkey handling** - No logging of key combinations  
- **✅ User-controlled data** - Easy clearing and deletion
- **✅ Focus-aware operations** - Respects current app context

## 🧪 Testing

```bash
swift test
```

Comprehensive test coverage for:
- Auto-paste functionality
- Pinned items management  
- Configurable hotkey system
- Timeout behavior
- Current item highlighting
- Mode switching logic

## 🎯 **Default Hotkeys**

| Hotkey | Action | Configurable |
|--------|--------|--------------|
| **⌘⇧C** | Show clipboard history | ✅ |
| **⌘⇧P** | Show pinned items | ✅ |
| **⌘⌥1-6** | Copy & paste items 1-6 | ✅ |

*All hotkeys can be customized in Settings → Configure Hotkeys*

## 🤝 Contributing

High-quality contributions welcome! Please ensure:
- All tests pass
- Code follows existing patterns
- New features include tests
- Documentation is updated

---

**Made with ❤️ for productivity enthusiasts who want lightning-fast clipboard access with zero friction.** 