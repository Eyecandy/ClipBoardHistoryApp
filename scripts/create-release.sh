#!/bin/bash

# GitHub Release Creation Script for ClipboardHistoryApp
# Usage: ./scripts/create-release.sh [version]

set -e

# Configuration
REPO_OWNER="Eyecandy"  # Change this to your GitHub username
REPO_NAME="ClipboardHistoryApp"
APP_NAME="ClipboardHistoryApp"

# Get version from argument or prompt
if [ -z "$1" ]; then
    echo "Enter version (e.g., v1.0.0):"
    read VERSION
else
    VERSION="$1"
fi

# Validate version format
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format. Use format: v1.0.0"
    exit 1
fi

echo "🚀 Creating GitHub release for $VERSION"

# Clean and build
echo "🧹 Cleaning previous builds..."
make clean

echo "🧪 Running tests..."
make test

echo "📦 Creating release package..."
make package

# Check if package exists
PACKAGE_FILE="dist/${APP_NAME}-${VERSION}.zip"
if [ ! -f "dist/${APP_NAME}-v1.0.zip" ]; then
    echo "❌ Package file not found at dist/${APP_NAME}-v1.0.zip"
    exit 1
fi

# Rename package to include version
mv "dist/${APP_NAME}-v1.0.zip" "$PACKAGE_FILE"

echo "✅ Package created: $PACKAGE_FILE"
echo "📊 Package size: $(du -h "$PACKAGE_FILE" | cut -f1)"

# Create release notes
RELEASE_NOTES_FILE="release-notes-${VERSION}.md"
cat > "$RELEASE_NOTES_FILE" << EOF
# ClipboardHistoryApp ${VERSION}

## 🎯 Features
- **7 Global Hotkeys**: ⌘⇧C (popup) + ⌘⇧1-6 (direct access)
- **Visual Indices**: Numbered items throughout interface
- **Smart Auto-Hide**: Popup pauses when mouse hovering
- **Focus Preservation**: Returns focus to original app after selection
- **Persistent History**: Up to 20 items saved between sessions
- **Full Text Viewing**: ⌘+Click to view complete content with scrolling
- **Customizable Settings**: Configure popup item count (1-20)

## 🔧 Technical Improvements
- **68 Comprehensive Tests**: Full test coverage with zero warnings
- **Clean Architecture**: Modular design with ClipboardHistoryCore library
- **Memory Safety**: Proper window management and cleanup
- **Professional UI**: Custom icons and polished interface

## 📥 Installation
1. Download \`${APP_NAME}-${VERSION}.zip\`
2. Unzip the file
3. Drag \`ClipboardHistoryApp.app\` to your Applications folder
4. Launch and grant accessibility permissions when prompted

## ⚠️ System Requirements
- macOS 13.0 or later
- Accessibility permissions required for global hotkeys

## 🛡️ Security & Privacy
- All clipboard data stays local on your device
- No network connections or data transmission
- Open source - audit the code yourself

---
**Full changelog available in [RELEASE_NOTES.md](RELEASE_NOTES.md)**
EOF

echo "📝 Release notes created: $RELEASE_NOTES_FILE"

# Instructions for manual release creation
echo ""
echo "🎯 Next Steps - Create GitHub Release:"
echo "1. Go to: https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/new"
echo "2. Tag version: $VERSION"
echo "3. Release title: ClipboardHistoryApp $VERSION"
echo "4. Copy release notes from: $RELEASE_NOTES_FILE"
echo "5. Upload package file: $PACKAGE_FILE"
echo "6. Mark as 'Latest release'"
echo ""
echo "📋 Files ready for upload:"
echo "   - Package: $PACKAGE_FILE ($(du -h "$PACKAGE_FILE" | cut -f1))"
echo "   - Notes: $RELEASE_NOTES_FILE"
echo ""
echo "✅ Release preparation complete!" 