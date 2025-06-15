# ClipboardHistoryApp Makefile
# Provides convenient commands for building, testing, and deploying

# Variables
APP_NAME = ClipboardHistoryApp
BUNDLE_NAME = $(APP_NAME).app
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
DEBUG_DIR = $(BUILD_DIR)/debug
APPLICATIONS_DIR = /Applications
EXECUTABLE_PATH = $(RELEASE_DIR)/$(APP_NAME)
BUNDLE_PATH = $(RELEASE_DIR)/$(BUNDLE_NAME)

# Default target
.PHONY: help
help:
	@echo "ClipboardHistoryApp Build System"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  build         - Build the app in debug mode"
	@echo "  release       - Build the app in release mode (optimized)"
	@echo "  run           - Build and run the app in debug mode"
	@echo "  test          - Run all unit tests"
	@echo "  bundle        - Create macOS app bundle for release"
	@echo "  install       - Install app bundle to /Applications"
	@echo "  uninstall     - Remove app from /Applications"
	@echo "  clean         - Clean all build artifacts"
	@echo "  clean-install - Clean, build, bundle, and install"
	@echo "  lint          - Run code quality checks"
	@echo "  package       - Create distributable package"
	@echo ""
	@echo "Development workflow:"
	@echo "  make run      - Quick development testing"
	@echo "  make test     - Verify all tests pass"
	@echo "  make install  - Deploy to Applications folder"

# Build targets
.PHONY: build
build:
	@echo "🔨 Building $(APP_NAME) in debug mode..."
	swift build

.PHONY: release
release:
	@echo "🚀 Building $(APP_NAME) in release mode..."
	swift build -c release

# Run target
.PHONY: run
run: build
	@echo "▶️  Running $(APP_NAME)..."
	swift run

# Test target
.PHONY: test
test:
	@echo "🧪 Running unit tests..."
	swift test

# Bundle creation
.PHONY: bundle
bundle: release
	@echo "📦 Creating macOS app bundle..."
	@mkdir -p $(BUNDLE_PATH)/Contents/MacOS
	@mkdir -p $(BUNDLE_PATH)/Contents/Resources
	@cp $(EXECUTABLE_PATH) $(BUNDLE_PATH)/Contents/MacOS/
	@if [ -f "LICENSE" ]; then \
		cp LICENSE $(BUNDLE_PATH)/Contents/Resources/; \
		echo "📄 Added LICENSE file to bundle"; \
	fi
	@if [ -f "README.md" ]; then \
		cp README.md $(BUNDLE_PATH)/Contents/Resources/; \
		echo "📄 Added README.md to bundle"; \
	fi
	@echo "📝 Creating Info.plist..."
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(BUNDLE_PATH)/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '<plist version="1.0">' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '<dict>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleExecutable</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>$(APP_NAME)</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleIdentifier</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>com.clipboardhistory.app</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleName</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>$(APP_NAME)</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleDisplayName</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>Clipboard History</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleVersion</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>1.0</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleShortVersionString</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>1.0</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundlePackageType</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>APPL</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>CFBundleSignature</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>????</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>LSMinimumSystemVersion</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<string>13.0</string>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>LSUIElement</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<true/>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>NSHighResolutionCapable</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<true/>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<key>NSSupportsAutomaticGraphicsSwitching</key>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '	<true/>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@if [ -d "Resources/$(APP_NAME).iconset" ]; then \
		echo "🎨 Adding app icons..."; \
		iconutil -c icns -o $(BUNDLE_PATH)/Contents/Resources/$(APP_NAME).icns Resources/$(APP_NAME).iconset; \
		echo '	<key>CFBundleIconFile</key>' >> $(BUNDLE_PATH)/Contents/Info.plist; \
		echo '	<string>$(APP_NAME)</string>' >> $(BUNDLE_PATH)/Contents/Info.plist; \
	fi
	@echo '</dict>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@echo '</plist>' >> $(BUNDLE_PATH)/Contents/Info.plist
	@chmod +x $(BUNDLE_PATH)/Contents/MacOS/$(APP_NAME)
	@echo "✅ App bundle created at $(BUNDLE_PATH)"

# Installation targets
.PHONY: install
install: bundle
	@echo "📲 Installing $(BUNDLE_NAME) to $(APPLICATIONS_DIR)..."
	@if [ -d "$(APPLICATIONS_DIR)/$(BUNDLE_NAME)" ]; then \
		echo "⚠️  Removing existing installation..."; \
		rm -rf "$(APPLICATIONS_DIR)/$(BUNDLE_NAME)"; \
	fi
	@cp -R $(BUNDLE_PATH) $(APPLICATIONS_DIR)/
	@echo "✅ $(APP_NAME) installed successfully!"
	@echo "   You can now find it in your Applications folder"
	@echo "   or launch it with: open $(APPLICATIONS_DIR)/$(BUNDLE_NAME)"

.PHONY: uninstall
uninstall:
	@echo "🗑️  Uninstalling $(BUNDLE_NAME) from $(APPLICATIONS_DIR)..."
	@if [ -d "$(APPLICATIONS_DIR)/$(BUNDLE_NAME)" ]; then \
		rm -rf "$(APPLICATIONS_DIR)/$(BUNDLE_NAME)"; \
		echo "✅ $(APP_NAME) uninstalled successfully!"; \
	else \
		echo "ℹ️  $(APP_NAME) is not installed in $(APPLICATIONS_DIR)"; \
	fi

# Clean targets
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ Clean complete"

.PHONY: clean-install
clean-install: clean install
	@echo "🎉 Clean install complete!"

# Development helpers
.PHONY: lint
lint:
	@echo "🔍 Running code quality checks..."
	@echo "📊 Build warnings check..."
	@swift build -c release 2>&1 | grep -i warning || echo "✅ No build warnings found"
	@echo "🧪 Test suite verification..."
	@swift test --quiet && echo "✅ All tests pass"

.PHONY: package
package: bundle
	@echo "📦 Creating distributable package..."
	@mkdir -p dist
	@zip -r dist/$(APP_NAME)-v1.0.zip $(BUNDLE_PATH)
	@echo "✅ Package created: dist/$(APP_NAME)-v1.0.zip"
	@echo "📊 Package size: $$(du -h dist/$(APP_NAME)-v1.0.zip | cut -f1)"

# Quick development workflow
.PHONY: dev
dev: test run

# Production deployment
.PHONY: deploy
deploy: clean test release bundle install
	@echo "🚀 Production deployment complete!"
	@echo "   App installed to: $(APPLICATIONS_DIR)/$(BUNDLE_NAME)"

# Status check
.PHONY: status
status:
	@echo "📊 ClipboardHistoryApp Status"
	@echo "============================="
	@echo "Build directory: $(BUILD_DIR)"
	@if [ -f "$(EXECUTABLE_PATH)" ]; then \
		echo "✅ Release binary: $(EXECUTABLE_PATH)"; \
	else \
		echo "❌ Release binary: Not built"; \
	fi
	@if [ -d "$(BUNDLE_PATH)" ]; then \
		echo "✅ App bundle: $(BUNDLE_PATH)"; \
	else \
		echo "❌ App bundle: Not created"; \
	fi
	@if [ -d "$(APPLICATIONS_DIR)/$(BUNDLE_NAME)" ]; then \
		echo "✅ Installed: $(APPLICATIONS_DIR)/$(BUNDLE_NAME)"; \
	else \
		echo "❌ Installed: Not found in Applications"; \
	fi

# Force rebuild
.PHONY: rebuild
rebuild: clean build

.PHONY: rebuild-release
rebuild-release: clean release

# GitHub release preparation
.PHONY: prepare-release
prepare-release:
	@echo "🚀 Preparing GitHub release..."
	@if [ ! -f "scripts/create-release.sh" ]; then \
		echo "❌ Release script not found. Run this from project root."; \
		exit 1; \
	fi
	@./scripts/create-release.sh 