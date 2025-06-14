#!/bin/bash

echo "🔨 Building ClipboardHistoryApp..."

# Build the app
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Copy to app bundle
cp .build/release/ClipboardHistoryApp ClipboardHistoryApp.app/Contents/MacOS/

# Ad-hoc sign the app for consistent identity
echo "✍️  Signing app..."
codesign --force --sign - ClipboardHistoryApp.app/Contents/MacOS/ClipboardHistoryApp

# Kill any running instances
pkill -f ClipboardHistoryApp 2>/dev/null

# Launch the app
echo "🚀 Launching app..."
open ClipboardHistoryApp.app

echo "✅ Done! App launched with consistent identity."
echo "💡 Accessibility permissions should now persist across rebuilds." 