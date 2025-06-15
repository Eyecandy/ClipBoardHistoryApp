import SwiftUI
import AppKit
import ClipboardHistoryCore

// Create and run the app
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var clipboardManager: ClipboardHistoryCore.ClipboardManager?
    var hotkeyManager: ClipboardHistoryCore.HotkeyManager?
    var clipboardPopup: ClipboardHistoryCore.ClipboardPopup?
    var fullTextWindow: NSWindow?
    var fullTextContent: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Check if this is first run and show disclaimer
        checkFirstRunDisclaimer()
        
        setupStatusItem()
        
        // Delay clipboard manager setup to avoid initialization issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupClipboardManager()
        }
        
        // Setup hotkey and popup even later to ensure everything is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.setupHotkeyManager()
            self.setupClipboardPopup()
        }
    }
    
    private func checkFirstRunDisclaimer() {
        let hasShownDisclaimer = UserDefaults.standard.bool(forKey: "HasShownLegalDisclaimer")
        if !hasShownDisclaimer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showFirstRunDisclaimer()
            }
        }
    }
    
    private func showFirstRunDisclaimer() {
        let alert = NSAlert()
        alert.messageText = "Welcome to ClipboardHistoryApp"
        alert.informativeText = """
        Before using this app, please read the complete license terms and disclaimers.
        
        By clicking "View License & Agree", you will see the full license text and can then accept the terms to continue using the app.
        
        You can also view the complete license at any time via the "License" menu item.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "View License & Agree")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn: // View License & Agree
            showFirstRunLicenseDialog()
        case .alertSecondButtonReturn: // Quit
            NSApplication.shared.terminate(nil)
        default:
            break
        }
    }
    
    private func showFirstRunLicenseDialog() {
        // Get the complete license text
        let licenseText = """
MIT License with Additional Terms

Copyright (c) 2024 ClipboardHistoryApp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

================================================================================
ADDITIONAL DISCLAIMERS AND LIMITATIONS
================================================================================

PRIVACY AND DATA HANDLING:
- This software accesses clipboard data solely for the purpose of providing
  clipboard history functionality
- All clipboard data is stored locally on the user's device
- No clipboard data is transmitted over networks or shared with third parties
- Users are responsible for ensuring they comply with applicable privacy laws
  and regulations when using this software

SECURITY CONSIDERATIONS:
- This software requires accessibility permissions to function
- Users should be aware that clipboard data may contain sensitive information
- The software does not encrypt stored clipboard data
- Users are advised to regularly clear clipboard history if handling sensitive data

SYSTEM COMPATIBILITY:
- This software is designed for macOS systems
- Compatibility with future macOS versions is not guaranteed
- Users should test the software in their specific environment before relying on it

LIMITATION OF LIABILITY:
- The authors and contributors shall not be liable for any data loss, security
  breaches, or system damage resulting from the use of this software
- Users assume all risks associated with the use of this software
- This software is provided for convenience and productivity purposes only

COMPLIANCE:
- Users are responsible for ensuring their use of this software complies with
  all applicable laws, regulations, and organizational policies
- The software should not be used in environments where clipboard monitoring
  is prohibited or restricted

By using this software, you acknowledge that you have read, understood, and
agree to be bound by these terms and disclaimers.
"""
        
        showFirstRunLicenseWindow(for: licenseText)
    }
    
    private func showFirstRunLicenseWindow(for text: String) {
        // Close any existing full text window first
        if let existingWindow = fullTextWindow {
            existingWindow.close()
            fullTextWindow = nil
            fullTextContent = nil
        }
        
        // Create a custom window for scrollable license display
        let windowRect = NSRect(x: 0, y: 0, width: 700, height: 600)
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "License Agreement - ClipboardHistoryApp"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false  // Prevent automatic release
        
        // Create main content view
        let contentView = NSView(frame: windowRect)
        window.contentView = contentView
        
        // Create scroll view for the text
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 80, width: windowRect.width - 40, height: windowRect.height - 140))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .bezelBorder
        scrollView.autoresizingMask = [.width, .height]
        
        // Create text view with proper setup for scrolling
        let textView = NSTextView()
        textView.string = text
        textView.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        
        // Configure text container for proper scrolling
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
        }
        
        // Set up the text view frame to match scroll view content size
        textView.frame = NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        // Set the document view and add to content view
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        // Force layout and ensure text is visible
        textView.needsLayout = true
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        
        // Scroll to top to ensure text is visible
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        
        // Create buttons
        let buttonHeight: CGFloat = 32
        let buttonWidth: CGFloat = 100
        let buttonSpacing: CGFloat = 10
        let buttonY: CGFloat = 20
        
        let agreeButton = NSButton(frame: NSRect(
            x: windowRect.width - (buttonWidth * 2) - buttonSpacing - 20,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        agreeButton.title = "I Agree"
        agreeButton.bezelStyle = .rounded
        agreeButton.target = self
        agreeButton.action = #selector(agreeToFirstRunLicense(_:))
        agreeButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(agreeButton)
        
        let quitButton = NSButton(frame: NSRect(
            x: windowRect.width - buttonWidth - 20,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        quitButton.title = "Quit"
        quitButton.bezelStyle = .rounded
        quitButton.target = self
        quitButton.action = #selector(quitFromFirstRunLicense(_:))
        quitButton.keyEquivalent = "\u{1b}" // Escape key
        quitButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(quitButton)
        
        // Add instruction label
        let instructionLabel = NSTextField(labelWithString: "Please read the complete license terms above, then click 'I Agree' to continue.")
        instructionLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        instructionLabel.textColor = NSColor.labelColor
        instructionLabel.frame = NSRect(x: 20, y: buttonY + 8, width: 400, height: 16)
        instructionLabel.autoresizingMask = [.maxXMargin, .maxYMargin]
        contentView.addSubview(instructionLabel)
        
        // Store the window and text for button actions
        fullTextWindow = window
        fullTextContent = text
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func agreeToFirstRunLicense(_ sender: NSButton) {
        UserDefaults.standard.set(true, forKey: "HasShownLegalDisclaimer")
        closeFullTextDialog(sender)
    }
    
    @objc private func quitFromFirstRunLicense(_ sender: NSButton) {
        NSApplication.shared.terminate(nil)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = createClipboardIcon()
            button.toolTip = "Clipboard History - Press ⌘⇧C for quick access"
        }
        updateMenu()
    }
    
    private func createClipboardIcon() -> NSImage? {
        // Try to use the modern clipboard system symbol first
        if let clipboardImage = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard History") {
            // Configure the symbol for menu bar use
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            return clipboardImage.withSymbolConfiguration(config)
        }
        
        // Fallback: Create a custom clipboard icon programmatically
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Set up the drawing context
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        // Clear the background
        context.clear(CGRect(origin: .zero, size: size))
        
        // Draw clipboard background (main rectangle)
        let clipboardRect = CGRect(x: 2, y: 1, width: 12, height: 14)
        context.setFillColor(NSColor.controlAccentColor.cgColor)
        context.fillEllipse(in: CGRect(x: 1, y: 0, width: 14, height: 16)) // Rounded background
        
        // Draw clipboard outline
        context.setStrokeColor(NSColor.labelColor.cgColor)
        context.setLineWidth(1.0)
        context.stroke(clipboardRect)
        
        // Draw clipboard clip at top
        let clipRect = CGRect(x: 5, y: 12, width: 6, height: 3)
        context.setFillColor(NSColor.secondaryLabelColor.cgColor)
        context.fill(clipRect)
        context.stroke(clipRect)
        
        // Draw some lines to represent text
        context.setStrokeColor(NSColor.labelColor.cgColor)
        context.setLineWidth(0.5)
        
        // Line 1
        context.move(to: CGPoint(x: 4, y: 9))
        context.addLine(to: CGPoint(x: 12, y: 9))
        context.strokePath()
        
        // Line 2
        context.move(to: CGPoint(x: 4, y: 7))
        context.addLine(to: CGPoint(x: 10, y: 7))
        context.strokePath()
        
        // Line 3
        context.move(to: CGPoint(x: 4, y: 5))
        context.addLine(to: CGPoint(x: 11, y: 5))
        context.strokePath()
        
        image.unlockFocus()
        
        // Make it template so it adapts to dark/light mode
        image.isTemplate = true
        
        return image
    }
    
    private func setupClipboardManager() {
        clipboardManager = ClipboardHistoryCore.ClipboardManager()
        clipboardManager?.delegate = self
        clipboardManager?.startMonitoring()
    }
    
    private func setupHotkeyManager() {
        hotkeyManager = ClipboardHistoryCore.HotkeyManager()
        hotkeyManager?.delegate = self
        hotkeyManager?.registerHotkey()
    }
    
    private func setupClipboardPopup() {
        clipboardPopup = ClipboardHistoryCore.ClipboardPopup()
        clipboardPopup?.delegate = self
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        addHotkeyInfoToMenu(menu)
        addHistoryItemsToMenu(menu)
        addUtilityOptionsToMenu(menu)
        
        statusItem?.menu = menu
    }
    
    private func addHotkeyInfoToMenu(_ menu: NSMenu) {
        // Add info about hotkey (only if hotkey manager is set up)
        guard hotkeyManager != nil else { return }
        
        let hotkeyInfo = NSMenuItem(
            title: "Press ⌘⇧C for quick access",
            action: nil,
            keyEquivalent: ""
        )
        hotkeyInfo.isEnabled = false
        menu.addItem(hotkeyInfo)
        
        let directHotkeyInfo = NSMenuItem(
            title: "⌘⌥1-6: Copy items 1-6 directly",
            action: nil,
            keyEquivalent: ""
        )
        directHotkeyInfo.isEnabled = false
        menu.addItem(directHotkeyInfo)
        
        let copyInfo = NSMenuItem(
            title: "Click: copy • ⌘+click: view full • Right-click: options",
            action: nil,
            keyEquivalent: ""
        )
        copyInfo.isEnabled = false
        menu.addItem(copyInfo)
        menu.addItem(NSMenuItem.separator())
    }
    
    private func addHistoryItemsToMenu(_ menu: NSMenu) {
        // Add clipboard history items
        let history = clipboardManager?.getHistory() ?? []
        
        if history.isEmpty {
            let emptyItem = NSMenuItem(
                title: "No clipboard history",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, item) in history.enumerated() {
                addHistoryItemToMenu(menu, item: item, index: index)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
    }
    
    private func addHistoryItemToMenu(_ menu: NSMenu, item: String, index: Int) {
        // Clean up multi-line text for menu display
        let cleanedText = item.cleanedForDisplay().truncated(to: 45)
        let menuTitle = "\(index + 1). \(cleanedText)"
        // Add keyboard shortcut for first 6 items
        let keyEquivalent = (index < 6) ? "\(index + 1)" : ""
        let menuItem = NSMenuItem(
            title: menuTitle,
            action: #selector(selectClipboardItem(_:)),
            keyEquivalent: keyEquivalent
        )
        if index < 6 {
            menuItem.keyEquivalentModifierMask = [.command, .option]
        }
        menuItem.tag = index
        menuItem.target = self
        
        // Add submenu for each item with options
        let submenu = NSMenu()
        
        let copyAction = NSMenuItem(
            title: "Copy",
            action: #selector(selectClipboardItem(_:)),
            keyEquivalent: ""
        )
        copyAction.tag = index
        copyAction.target = self
        submenu.addItem(copyAction)
        
        let viewFullAction = NSMenuItem(
            title: "View Full Text",
            action: #selector(viewFullClipboardItem(_:)),
            keyEquivalent: ""
        )
        viewFullAction.tag = index
        viewFullAction.target = self
        submenu.addItem(viewFullAction)
        
        let deleteAction = NSMenuItem(
            title: "Delete",
            action: #selector(deleteClipboardItem(_:)),
            keyEquivalent: ""
        )
        deleteAction.tag = index
        deleteAction.target = self
        submenu.addItem(deleteAction)
        
        menuItem.submenu = submenu
        menu.addItem(menuItem)
    }
    
    private func addUtilityOptionsToMenu(_ menu: NSMenu) {
        let history = clipboardManager?.getHistory() ?? []
        
        // Add clear history option
        if !history.isEmpty {
            let clearItem = NSMenuItem(
                title: "Clear History",
                action: #selector(clearHistory),
                keyEquivalent: ""
            )
            clearItem.target = self
            menu.addItem(clearItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add settings submenu
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu()
        
        // Add popup item count setting with clearer description
        let popupSettingsItem = NSMenuItem(title: "⌘⇧C Popup Items", action: nil, keyEquivalent: "")
        let popupSubmenu = NSMenu()
        
        let currentCount = clipboardManager?.getPopupItemCount() ?? 3
        
        for count in 1...20 {
            let countItem = NSMenuItem(
                title: "\(count) item\(count == 1 ? "" : "s") in ⌘⇧C popup",
                action: #selector(setPopupItemCount(_:)),
                keyEquivalent: ""
            )
            countItem.tag = count
            countItem.target = self
            countItem.state = (count == currentCount) ? .on : .off
            popupSubmenu.addItem(countItem)
        }
        
        popupSettingsItem.submenu = popupSubmenu
        settingsSubmenu.addItem(popupSettingsItem)
        
        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add user manual option
        let manualItem = NSMenuItem(title: "User Manual", action: #selector(showUserManual), keyEquivalent: "")
        manualItem.target = self
        menu.addItem(manualItem)
        
        // Add about/license option
        let aboutItem = NSMenuItem(title: "About ClipboardHistoryApp", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Add license option
        let licenseItem = NSMenuItem(title: "License", action: #selector(showLicense), keyEquivalent: "")
        licenseItem.target = self
        menu.addItem(licenseItem)
        
        // Add quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc func selectClipboardItem(_ sender: NSMenuItem) {
        guard let history = clipboardManager?.getHistory(),
              sender.tag >= 0,
              sender.tag < history.count else { 
            return 
        }
        
        let selectedItem = history[sender.tag]
        
        // Copy to clipboard - user can paste manually with ⌘V
        clipboardManager?.copySelectedItem(selectedItem)
    }
    
    @objc func clearHistory() {
        clipboardManager?.clearHistory()
        updateMenu()
    }
    
    @objc func deleteClipboardItem(_ sender: NSMenuItem) {
        clipboardManager?.deleteItem(at: sender.tag)
    }
    
    @objc func setPopupItemCount(_ sender: NSMenuItem) {
        clipboardManager?.setPopupItemCount(sender.tag)
        updateMenu() // Refresh menu to show new selection
    }
    
    @objc func viewFullClipboardItem(_ sender: NSMenuItem) {
        guard let history = clipboardManager?.getHistory(),
              sender.tag >= 0,
              sender.tag < history.count else { 
            return 
        }
        
        let item = history[sender.tag]
        showFullTextDialog(for: item)
    }
    
    private func showFullTextDialog(for text: String) {
        // Close any existing full text window first
        if let existingWindow = fullTextWindow {
            existingWindow.close()
            fullTextWindow = nil
            fullTextContent = nil
        }
        
        // Create a custom window for scrollable text display
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 500)
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Full Clipboard Content"
        window.center()
        window.minSize = NSSize(width: 400, height: 300)
        window.delegate = self
        window.isReleasedWhenClosed = false  // Prevent automatic release
        
        // Create main content view
        let contentView = NSView(frame: windowRect)
        window.contentView = contentView
        
        // Create scroll view for the text
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: windowRect.width - 40, height: windowRect.height - 120))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .bezelBorder
        scrollView.autoresizingMask = [.width, .height]
        
        // Create text view with proper setup for scrolling
        let textView = NSTextView()
        textView.string = text
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        
        // Configure text container for proper scrolling
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
        }
        
        // Set up the text view frame to match scroll view content size
        textView.frame = NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        // Set the document view and add to content view
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        // Force layout and ensure text is visible
        textView.needsLayout = true
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        
        // Scroll to top to ensure text is visible
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        
        // Create buttons
        let buttonHeight: CGFloat = 32
        let buttonWidth: CGFloat = 80
        let buttonSpacing: CGFloat = 10
        let buttonY: CGFloat = 20
        
        let copyButton = NSButton(frame: NSRect(
            x: windowRect.width - (buttonWidth * 2) - buttonSpacing - 20,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        copyButton.title = "Copy"
        copyButton.bezelStyle = .rounded
        copyButton.target = self
        copyButton.action = #selector(copyFromFullTextDialog(_:))
        copyButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(copyButton)
        
        let closeButton = NSButton(frame: NSRect(
            x: windowRect.width - buttonWidth - 20,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeFullTextDialog(_:))
        closeButton.keyEquivalent = "\u{1b}" // Escape key
        closeButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(closeButton)
        
        // Add character count label
        let charCountLabel = NSTextField(labelWithString: "Characters: \(text.count)")
        charCountLabel.font = NSFont.systemFont(ofSize: 11)
        charCountLabel.textColor = NSColor.secondaryLabelColor
        charCountLabel.frame = NSRect(x: 20, y: buttonY + 8, width: 200, height: 16)
        charCountLabel.autoresizingMask = [.maxXMargin, .maxYMargin]
        contentView.addSubview(charCountLabel)
        
        // Store the window and text for button actions
        fullTextWindow = window
        fullTextContent = text
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func copyFromFullTextDialog(_ sender: NSButton) {
        guard let text = fullTextContent else { return }
        clipboardManager?.copySelectedItem(text)
        closeFullTextDialog(sender)
    }
    
    @objc private func closeFullTextDialog(_ sender: NSButton) {
        // Close the window safely
        if let window = fullTextWindow {
            window.delegate = nil  // Remove delegate to prevent callbacks
            window.close()
            fullTextWindow = nil
            fullTextContent = nil
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "ClipboardHistoryApp v1.0"
        alert.informativeText = """
        A professional macOS clipboard history manager with global hotkeys.
        
        Features:
        • 7 Global Hotkeys (⌘⇧C + ⌘⇧1-6)
        • Visual numbered indices
        • Smart auto-hide with mouse tracking
        • Focus preservation
        • Persistent history (up to 20 items)
        • Full text viewing with ⌘+Click
        
        ⚠️ IMPORTANT DISCLAIMERS:
        • Software provided "AS IS" without warranty
        • Users responsible for compliance with applicable laws
        • Clipboard data may contain sensitive information
        • All data stored locally on your device only
        • Not liable for data loss or security issues
        
        Copyright © 2024 ClipboardHistoryApp
        Licensed under MIT License with Additional Terms
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func showLicense() {
        // Read the complete license text from the LICENSE file content
        let licenseText = """
MIT License with Additional Terms

Copyright (c) 2024 ClipboardHistoryApp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

================================================================================
ADDITIONAL DISCLAIMERS AND LIMITATIONS
================================================================================

PRIVACY AND DATA HANDLING:
- This software accesses clipboard data solely for the purpose of providing
  clipboard history functionality
- All clipboard data is stored locally on the user's device
- No clipboard data is transmitted over networks or shared with third parties
- Users are responsible for ensuring they comply with applicable privacy laws
  and regulations when using this software

SECURITY CONSIDERATIONS:
- This software requires accessibility permissions to function
- Users should be aware that clipboard data may contain sensitive information
- The software does not encrypt stored clipboard data
- Users are advised to regularly clear clipboard history if handling sensitive data

SYSTEM COMPATIBILITY:
- This software is designed for macOS systems
- Compatibility with future macOS versions is not guaranteed
- Users should test the software in their specific environment before relying on it

LIMITATION OF LIABILITY:
- The authors and contributors shall not be liable for any data loss, security
  breaches, or system damage resulting from the use of this software
- Users assume all risks associated with the use of this software
- This software is provided for convenience and productivity purposes only

COMPLIANCE:
- Users are responsible for ensuring their use of this software complies with
  all applicable laws, regulations, and organizational policies
- The software should not be used in environments where clipboard monitoring
  is prohibited or restricted

By using this software, you acknowledge that you have read, understood, and
agree to be bound by these terms and disclaimers.
"""
        
        showLicenseDialog(for: licenseText)
    }
    
    private func showLicenseDialog(for text: String) {
        // Close any existing full text window first
        if let existingWindow = fullTextWindow {
            existingWindow.close()
            fullTextWindow = nil
            fullTextContent = nil
        }
        
        // Create a custom window for scrollable license display
        let windowRect = NSRect(x: 0, y: 0, width: 700, height: 600)
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "License - ClipboardHistoryApp"
        window.center()
        window.minSize = NSSize(width: 500, height: 400)
        window.delegate = self
        window.isReleasedWhenClosed = false  // Prevent automatic release
        
        // Create main content view
        let contentView = NSView(frame: windowRect)
        window.contentView = contentView
        
        // Create scroll view for the text
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: windowRect.width - 40, height: windowRect.height - 120))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .bezelBorder
        scrollView.autoresizingMask = [.width, .height]
        
        // Create text view with proper setup for scrolling
        let textView = NSTextView()
        textView.string = text
        textView.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        
        // Configure text container for proper scrolling
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
        }
        
        // Set up the text view frame to match scroll view content size
        textView.frame = NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        // Set the document view and add to content view
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        // Force layout and ensure text is visible
        textView.needsLayout = true
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        
        // Scroll to top to ensure text is visible
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        
        // Create close button
        let buttonHeight: CGFloat = 32
        let buttonWidth: CGFloat = 80
        let buttonY: CGFloat = 20
        
        let closeButton = NSButton(frame: NSRect(
            x: windowRect.width - buttonWidth - 20,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeFullTextDialog(_:))
        closeButton.keyEquivalent = "\u{1b}" // Escape key
        closeButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(closeButton)
        
        // Add character count label
        let charCountLabel = NSTextField(labelWithString: "Characters: \(text.count)")
        charCountLabel.font = NSFont.systemFont(ofSize: 11)
        charCountLabel.textColor = NSColor.secondaryLabelColor
        charCountLabel.frame = NSRect(x: 20, y: buttonY + 8, width: 200, height: 16)
        charCountLabel.autoresizingMask = [.maxXMargin, .maxYMargin]
        contentView.addSubview(charCountLabel)
        
        // Store the window and text for button actions
        fullTextWindow = window
        fullTextContent = text
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showUserManual() {
        let manualText = """
ClipboardHistoryApp - User Manual

🚀 QUICK START
After launching, you'll see a clipboard icon in your menu bar.
The app automatically tracks everything you copy (up to 20 items).

⌨️ GLOBAL HOTKEYS (Your Main Interface)

🎯 ⌘⇧C - Quick Popup
• Shows floating popup with recent clipboard items
• Click to copy, ⌘+Click to view full text, Right-click for options
• Auto-hides after 10 seconds (pauses when mouse hovers)

🎯 ⌘⌥1-6 - Direct Access
• ⌘⌥1: Copy most recent item instantly
• ⌘⌥2: Copy 2nd most recent item
• ⌘⌥3-6: Copy 3rd-6th items
• Silent operation - no popup, maximum speed

📋 MENU BAR ACCESS
Click the clipboard icon to:
• View all history items (numbered 1, 2, 3...) with ⌘⌥1, ⌘⌥2, ⌘⌥3, etc.
• Access settings: ⌘⇧C Popup Items (1-20 items)
• Clear history or delete individual items

🔧 KEY FEATURES
• Focus Preservation: Returns to your original app after selection
• Copy-Only Workflow: Select item → it's copied → paste with ⌘V
• Persistent History: Items saved between app sessions
• Smart Text Handling: Full content preserved, truncated for display

💡 WORKFLOW TIPS
• Use ⌘⌥1-6 for frequently accessed items
• Use ⌘⇧C popup when you need to see and choose
• Use ⌘+Click to preview long text before copying
• Adjust popup item count in Settings to match your needs

🔒 PRIVACY
• All data stored locally on your device
• No network transmission or cloud storage
• Clear history regularly if handling sensitive data

For more info: About ClipboardHistoryApp • License
"""
        
        showUserManualDialog(for: manualText)
    }
    
    private func showUserManualDialog(for text: String) {
        // Close any existing full text window first
        if let existingWindow = fullTextWindow {
            existingWindow.close()
            fullTextWindow = nil
            fullTextContent = nil
        }
        
        // Create a custom window for scrollable manual display
        let windowRect = NSRect(x: 0, y: 0, width: 650, height: 500)
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "User Manual - ClipboardHistoryApp"
        window.center()
        window.minSize = NSSize(width: 500, height: 400)
        window.delegate = self
        window.isReleasedWhenClosed = false  // Prevent automatic release
        
        // Create main content view
        let contentView = NSView(frame: windowRect)
        window.contentView = contentView
        
        // Create scroll view for the text
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: windowRect.width - 40, height: windowRect.height - 120))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .bezelBorder
        scrollView.autoresizingMask = [.width, .height]
        
        // Create text view with proper setup for scrolling
        let textView = NSTextView()
        textView.string = text
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        
        // Configure text container for proper scrolling
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
        }
        
        // Set up the text view frame to match scroll view content size
        textView.frame = NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        // Set the document view and add to content view
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        // Force layout and ensure text is visible
        textView.needsLayout = true
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        
        // Scroll to top to ensure text is visible
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        
        // Create close button
        let buttonHeight: CGFloat = 32
        let buttonWidth: CGFloat = 80
        let buttonY: CGFloat = 20
        
        let closeButton = NSButton(frame: NSRect(
            x: windowRect.width - buttonWidth - 20,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeFullTextDialog(_:))
        closeButton.keyEquivalent = "\u{1b}" // Escape key
        closeButton.autoresizingMask = [.minXMargin, .maxYMargin]
        contentView.addSubview(closeButton)
        
        // Add character count label
        let charCountLabel = NSTextField(labelWithString: "User Manual - \(text.count) characters")
        charCountLabel.font = NSFont.systemFont(ofSize: 11)
        charCountLabel.textColor = NSColor.secondaryLabelColor
        charCountLabel.frame = NSRect(x: 20, y: buttonY + 8, width: 300, height: 16)
        charCountLabel.autoresizingMask = [.maxXMargin, .maxYMargin]
        contentView.addSubview(charCountLabel)
        
        // Store the window and text for button actions
        fullTextWindow = window
        fullTextContent = text
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func resetDisclaimer() {
        UserDefaults.standard.removeObject(forKey: "HasShownLegalDisclaimer")
        let alert = NSAlert()
        alert.messageText = "Legal Disclaimer Reset"
        alert.informativeText = "The legal disclaimer will be shown again on next app launch."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quit() {
        // Clean up full text window if open
        if let window = fullTextWindow {
            window.delegate = nil
            window.close()
            fullTextWindow = nil
            fullTextContent = nil
        }
        
        hotkeyManager?.unregisterHotkey()
        clipboardManager?.stopMonitoring()
        clipboardPopup?.hide()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Ensure history is saved when app quits
        clipboardManager?.saveHistoryOnExit()
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up when full text window is closed
        if let window = notification.object as? NSWindow,
           window === fullTextWindow {
            // Remove delegate to prevent further callbacks
            window.delegate = nil
            fullTextWindow = nil
            fullTextContent = nil
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Always allow window to close
        return true
    }
}

// MARK: - ClipboardManagerDelegate
extension AppDelegate: ClipboardHistoryCore.ClipboardManagerDelegate {
    func clipboardDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMenu()
        }
    }
}

// MARK: - HotkeyManagerDelegate
extension AppDelegate: ClipboardHistoryCore.HotkeyManagerDelegate {
    func hotkeyPressed() {
        DispatchQueue.main.async { [weak self] in
            guard let history = self?.clipboardManager?.getHistory() else { 
                return 
            }
            
            let maxItems = self?.clipboardManager?.getPopupItemCount() ?? 3
            self?.clipboardPopup?.show(with: history, maxItems: maxItems)
        }
    }
    
    func quitHotkeyPressed() {
        DispatchQueue.main.async { [weak self] in
            self?.quit()
        }
    }
    
    func directHotkeyPressed(for index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let history = self?.clipboardManager?.getHistory(),
                  index < history.count else {
                // Direct hotkey pressed but insufficient items available
                return
            }
            
            let selectedItem = history[index]
            // Direct hotkey pressed - copying item silently for security
            self?.clipboardManager?.copySelectedItem(selectedItem)
        }
    }
}

// MARK: - ClipboardPopupDelegate  
extension AppDelegate: ClipboardHistoryCore.ClipboardPopupDelegate {
    func popupDidSelectItem(_ item: String) {
        // Simply copy to clipboard - user can paste manually with ⌘V
        clipboardManager?.copySelectedItem(item)
    }
    
    func popupDidRequestFullView(_ item: String) {
        showFullTextDialog(for: item)
    }
    
    func popupDidRequestDelete(_ item: String) {
        guard let history = clipboardManager?.getHistory(),
              let index = history.firstIndex(of: item) else { 
            return 
        }
        clipboardManager?.deleteItem(at: index)
    }
} 
