import Foundation
import AppKit

public protocol ClipboardPopupDelegate: AnyObject {
    func popupDidSelectItem(_ item: String)
    func popupDidRequestFullView(_ item: String)
    func popupDidRequestDelete(_ item: String)
    func popupDidRequestPin(_ item: String)
    func popupDidRequestPaste(_ item: String) // For direct paste without bringing app to foreground
}

// Custom view class to handle mouse events and store index
class ClipboardItemView: NSView {
    var index: Int = 0
    var isCurrentClipboardItem: Bool = false
    var isPinnedItem: Bool = false
    weak var popup: ClipboardPopup?
    
    override func mouseEntered(with event: NSEvent) {
        wantsLayer = true
        if isCurrentClipboardItem {
            layer?.backgroundColor = NSColor.selectedControlColor.withAlphaComponent(0.5).cgColor
        } else {
            layer?.backgroundColor = NSColor.selectedControlColor.withAlphaComponent(0.3).cgColor
        }
        
        // Select item on hover (ready for Enter paste)
        popup?.itemHovered(at: index)
        
        // Notify popup that mouse is inside
        popup?.mouseEnteredPopup()
    }
    
    override func mouseExited(with event: NSEvent) {
        if isCurrentClipboardItem {
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.2).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        // Clear hovered item when mouse exits
        popup?.itemUnhovered()
        
        // Check if mouse is still within popup bounds
        if let popup = popup, let window = popup.window {
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            let isStillInside = windowFrame.contains(mouseLocation)
            
            if !isStillInside {
                popup.mouseExitedPopup()
            }
        }
    }
    

    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 18...26, 28: // Number keys 1-9 (18=1, 19=2, 20=3, 21=4, 23=5, 22=6, 26=7, 28=8, 25=9)
            let numberKeyPressed = getNumberFromKeyCode(event.keyCode)
            if let number = numberKeyPressed, number >= 1 && number <= 9 {
                let targetIndex = number - 1
                popup?.itemNumberKeyPressed(at: targetIndex)
            }
        case 126: // Up arrow
            popup?.navigateUp(from: index)
        case 125: // Down arrow
            popup?.navigateDown(from: index)
        case 53: // Escape key
            popup?.hide()
        default:
            super.keyDown(with: event)
        }
    }
    
    private func getNumberFromKeyCode(_ keyCode: UInt16) -> Int? {
        switch keyCode {
        case 18: return 1
        case 19: return 2
        case 20: return 3
        case 21: return 4
        case 23: return 5
        case 22: return 6
        case 26: return 7
        case 28: return 8
        case 25: return 9
        default: return nil
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // Command+click to view full text
            popup?.itemCommandClicked(at: index)
        } else if event.clickCount == 2 {
            // Double-click to view full text (keep as fallback)
            popup?.itemDoubleClicked(at: index)
        } else {
            // Single click to paste immediately (changed from copy-only)
            popup?.itemClickedForPaste(at: index)
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        popup?.itemRightClicked(at: index, event: event)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

public class ClipboardPopup: NSObject {
    public weak var delegate: ClipboardPopupDelegate?
    private(set) var window: NSWindow?
    private var clipboardItems: [String] = []
    private var isPinnedMode: Bool = false
    private var currentClipboardItem: String?
    private var eventMonitor: Any?
    private var previousActiveApp: NSRunningApplication?
    private var autoHideTimer: Timer?
    private var isMouseInside = false
    private var currentTimeout: Int = 10
    private var hoveredItemIndex: Int? = nil
    
    public override init() {
        super.init()
    }
    
    public func show(with items: [String], maxItems: Int = 3, isPinned: Bool = false, currentClipboard: String? = nil, timeout: Int = 10) {
        hide() // Hide any existing popup
        
        // Capture the currently active app before showing popup
        previousActiveApp = NSWorkspace.shared.frontmostApplication
        
        let validatedMaxItems = max(1, min(20, maxItems))
        clipboardItems = Array(items.prefix(validatedMaxItems))
        isPinnedMode = isPinned
        currentClipboardItem = currentClipboard
        currentTimeout = timeout
        
        guard !clipboardItems.isEmpty else { 
            return 
        }
        
        let mouseLocation = NSEvent.mouseLocation
        createWindow(at: mouseLocation, timeout: timeout)
    }
    
    public func hide() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        
        // Cancel auto-hide timer
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        
        window?.orderOut(nil)
        window = nil
        
        // Clear the previous app reference when hiding without selection
        previousActiveApp = nil
        isMouseInside = false
    }
    
    private func restorePreviousAppFocus() {
        // Restore focus to the previous app after a short delay to ensure clipboard operation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            if let previousApp = self?.previousActiveApp,
               previousApp.isTerminated == false {
                // Use activateWithOptions for better focus restoration
                previousApp.activate(options: [.activateIgnoringOtherApps])
            }
            self?.previousActiveApp = nil
        }
    }
    
    public func isVisible() -> Bool {
        return window?.isVisible ?? false
    }
    
    func itemClicked(at index: Int) {
        guard index < clipboardItems.count else { 
            return 
        }
        let selectedItem = clipboardItems[index]
        delegate?.popupDidSelectItem(selectedItem)
        hide()
        
        // Restore focus to the previous app after a short delay
        restorePreviousAppFocus()
    }
    
    func itemClickedForPaste(at index: Int) {
        guard index < clipboardItems.count else { 
            return 
        }
        let selectedItem = clipboardItems[index]
        
        // Store previous app before hiding
        let previousApp = self.previousActiveApp
        
        // Hide popup completely first
        hide()
        
        // Ensure window is fully dismissed and focus restored
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            // Activate previous app to restore cursor/focus
            if let previousApp = previousApp,
               previousApp.isTerminated == false {
                previousApp.activate(options: [.activateIgnoringOtherApps])
                
                // Wait for focus to fully settle (cursor should reappear)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self?.delegate?.popupDidRequestPaste(selectedItem)
                }
            }
        }
    }
    
    func itemHovered(at index: Int) {
        guard index < clipboardItems.count else { 
            return 
        }
        hoveredItemIndex = index
        let selectedItem = clipboardItems[index]
        // Copy to clipboard on hover - user can click to paste
        delegate?.popupDidSelectItem(selectedItem)
    }
    
    func itemUnhovered() {
        hoveredItemIndex = nil
    }
    
    func itemNumberKeyPressed(at index: Int) {
        guard index < clipboardItems.count else { 
            return 
        }
        let selectedItem = clipboardItems[index]
        
        // Store previous app before hiding
        let previousApp = self.previousActiveApp
        
        // Hide popup completely first
        hide()
        
        // Ensure window is fully dismissed and focus restored
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            // Activate previous app to restore cursor/focus
            if let previousApp = previousApp,
               previousApp.isTerminated == false {
                previousApp.activate(options: [.activateIgnoringOtherApps])
                
                // Wait for focus to fully settle (cursor should reappear)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self?.delegate?.popupDidRequestPaste(selectedItem)
                }
            }
        }
    }
    
    func itemDoubleClicked(at index: Int) {
        guard index < clipboardItems.count else { 
            return 
        }
        let selectedItem = clipboardItems[index]
        delegate?.popupDidRequestFullView(selectedItem)
        hide()
    }
    
    func itemCommandClicked(at index: Int) {
        guard index < clipboardItems.count else { 
            return 
        }
        let selectedItem = clipboardItems[index]
        delegate?.popupDidRequestFullView(selectedItem)
        hide()
    }
    
    func itemRightClicked(at index: Int, event: NSEvent) {
        guard index < clipboardItems.count else { 
            return 
        }
        let selectedItem = clipboardItems[index]
        showContextMenu(for: selectedItem, at: index, event: event)
    }
    
    func navigateUp(from currentIndex: Int) {
        let targetIndex = max(0, currentIndex - 1)
        setFirstResponder(to: targetIndex)
    }
    
    func navigateDown(from currentIndex: Int) {
        let targetIndex = min(clipboardItems.count - 1, currentIndex + 1)
        setFirstResponder(to: targetIndex)
    }
    
    private func setFirstResponder(to index: Int) {
        guard let window = window else { return }
        
        // Clear existing highlights first
        clearAllHighlights()
        
        // Find and focus the item view at the specified index
        if let contentView = window.contentView {
            // Check direct subviews first
            for subview in contentView.subviews {
                if let itemView = subview as? ClipboardItemView, itemView.index == index {
                    window.makeFirstResponder(itemView)
                    highlightItemView(itemView)
                    return
                }
                // Also check scroll view content
                if let scrollView = subview as? NSScrollView,
                   let documentView = scrollView.documentView {
                    for docSubview in documentView.subviews {
                        if let itemView = docSubview as? ClipboardItemView, itemView.index == index {
                            window.makeFirstResponder(itemView)
                            highlightItemView(itemView)
                            
                            // Auto-scroll to keep the focused item visible
                            let itemFrame = itemView.frame
                            scrollView.contentView.scrollToVisible(itemFrame)
                            return
                        }
                    }
                }
            }
        }
    }
    
    private func clearAllHighlights() {
        guard let window = window, let contentView = window.contentView else { return }
        
        // Clear highlights from all item views
        for subview in contentView.subviews {
            if let itemView = subview as? ClipboardItemView {
                clearHighlight(from: itemView)
            }
            // Also check scroll view content
            if let scrollView = subview as? NSScrollView,
               let documentView = scrollView.documentView {
                for docSubview in documentView.subviews {
                    if let itemView = docSubview as? ClipboardItemView {
                        clearHighlight(from: itemView)
                    }
                }
            }
        }
    }
    
    private func highlightItemView(_ itemView: ClipboardItemView) {
        itemView.wantsLayer = true
        itemView.layer?.backgroundColor = NSColor.selectedControlColor.withAlphaComponent(0.3).cgColor
        itemView.layer?.borderColor = NSColor.controlAccentColor.cgColor
        itemView.layer?.borderWidth = 2.0
    }
    
    private func clearHighlight(from itemView: ClipboardItemView) {
        itemView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        itemView.layer?.borderColor = NSColor.separatorColor.cgColor
        itemView.layer?.borderWidth = 0.5
    }
    
    private func showContextMenu(for item: String, at index: Int, event: NSEvent) {
        let menu = NSMenu()
        
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(contextMenuPaste), keyEquivalent: "")
        pasteItem.representedObject = item
        pasteItem.target = self
        menu.addItem(pasteItem)
        
        let copyItem = NSMenuItem(title: "Copy Only", action: #selector(contextMenuCopy), keyEquivalent: "")
        copyItem.representedObject = item
        copyItem.target = self
        menu.addItem(copyItem)
        
        let viewFullItem = NSMenuItem(
            title: "View Full Text",
            action: #selector(contextMenuViewFull),
            keyEquivalent: ""
        )
        viewFullItem.representedObject = item
        viewFullItem.target = self
        menu.addItem(viewFullItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Pin/Unpin option
        if isPinnedMode {
            let unpinItem = NSMenuItem(title: "Unpin", action: #selector(contextMenuUnpin), keyEquivalent: "")
            unpinItem.representedObject = item
            unpinItem.target = self
            menu.addItem(unpinItem)
        } else {
            let pinItem = NSMenuItem(title: "Pin Item", action: #selector(contextMenuPin), keyEquivalent: "")
            pinItem.representedObject = item
            pinItem.target = self
            menu.addItem(pinItem)
        }
        
        let deleteItem = NSMenuItem(title: "Delete", action: #selector(contextMenuDelete), keyEquivalent: "")
        deleteItem.representedObject = item
        deleteItem.target = self
        menu.addItem(deleteItem)
        
        NSMenu.popUpContextMenu(menu, with: event, for: window?.contentView ?? NSView())
    }
    
    @objc private func contextMenuPaste(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? String else { return }
        delegate?.popupDidRequestPaste(item)
        hide()
        restorePreviousAppFocus()
    }
    
    @objc private func contextMenuCopy(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? String {
            delegate?.popupDidSelectItem(item)
            hide()
            
            // Restore focus to the previous app after a short delay
            restorePreviousAppFocus()
        }
    }
    
    @objc private func contextMenuViewFull(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? String {
            delegate?.popupDidRequestFullView(item)
            hide()
        }
    }
    
    @objc private func contextMenuUnpin(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? String {
            delegate?.popupDidRequestPin(item)
            hide()
        }
    }
    
    @objc private func contextMenuPin(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? String {
            delegate?.popupDidRequestPin(item)
            hide()
        }
    }
    
    @objc private func contextMenuDelete(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? String {
            delegate?.popupDidRequestDelete(item)
            hide()
        }
    }
    
    private func createWindow(at location: NSPoint, timeout: Int) {
        let windowDimensions = calculateWindowDimensions()
        let windowOrigin = calculateWindowPosition(
            at: location,
            windowWidth: windowDimensions.width,
            windowHeight: windowDimensions.height
        )
        
        let windowRect = NSRect(
            x: windowOrigin.x,
            y: windowOrigin.y,
            width: windowDimensions.width,
            height: windowDimensions.height
        )
        
        window = createStyledWindow(with: windowRect)
        setupWindowContent(windowDimensions: windowDimensions)
        showAndConfigureWindow(timeout: timeout)
    }
    
    private func calculateWindowDimensions() -> (width: CGFloat, height: CGFloat) {
        let itemHeight: CGFloat = 60 // Fixed height per item for consistency
        let windowWidth: CGFloat = 350
        let maxWindowHeight: CGFloat = 400 // Maximum popup height
        let idealHeight = CGFloat(clipboardItems.count) * itemHeight
        
        // Limit window height to screen space
        if let screen = NSScreen.main {
            let screenHeight = screen.visibleFrame.height
            let maxAllowedHeight = min(maxWindowHeight, screenHeight * 0.7) // Use max 70% of screen height
            let windowHeight = min(idealHeight, maxAllowedHeight)
            return (width: windowWidth, height: windowHeight)
        }
        
        let windowHeight = min(idealHeight, maxWindowHeight)
        return (width: windowWidth, height: windowHeight)
    }

    
    private func calculateWindowPosition(
        at location: NSPoint,
        windowWidth: CGFloat,
        windowHeight: CGFloat
    ) -> NSPoint {
        // Position window near cursor but ensure it's on screen
        var windowOrigin = NSPoint(x: location.x + 10, y: location.y - windowHeight - 10)
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            if windowOrigin.x + windowWidth > screenFrame.maxX {
                windowOrigin.x = location.x - windowWidth - 10
            }
            if windowOrigin.y < screenFrame.minY {
                windowOrigin.y = location.y + 10
            }
        }
        
        return windowOrigin
    }
    
    private func createStyledWindow(with rect: NSRect) -> NSWindow {
        let newWindow = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        newWindow.level = .floating
        newWindow.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        newWindow.hasShadow = true
        newWindow.isOpaque = false
        
        return newWindow
    }
    
    private func setupWindowContent(windowDimensions: (width: CGFloat, height: CGFloat)) {
        guard let window = window else { return }
        
        let itemHeight: CGFloat = 60
        let totalContentHeight = CGFloat(clipboardItems.count) * itemHeight
        let needsScrolling = totalContentHeight > windowDimensions.height
        
        // Create main content view
        let contentView = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: windowDimensions.width,
                height: windowDimensions.height
            )
        )
        window.contentView = contentView
        
        if needsScrolling {
            setupScrollableContent(contentView: contentView, windowDimensions: windowDimensions)
        } else {
            setupStaticContent(contentView: contentView, windowDimensions: windowDimensions)
        }
    }
    
    private func setupScrollableContent(contentView: NSView, windowDimensions: (width: CGFloat, height: CGFloat)) {
        let itemHeight: CGFloat = 60
        let totalContentHeight = CGFloat(clipboardItems.count) * itemHeight
        
        // Create scroll view
        let scrollView = NSScrollView(
            frame: NSRect(x: 0, y: 0, width: windowDimensions.width, height: windowDimensions.height)
        )
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .overlay
        
        // Create document view for all content
        let documentView = NSView(
            frame: NSRect(x: 0, y: 0, width: windowDimensions.width - 15, height: totalContentHeight) // -15 for scroller
        )
        
        // Add clipboard items to document view
        for (index, item) in clipboardItems.enumerated() {
            let itemView = createItemView(
                item: item,
                index: index,
                frame: NSRect(
                    x: 0,
                    y: totalContentHeight - CGFloat(index + 1) * itemHeight,
                    width: windowDimensions.width - 15, // Account for scrollbar
                    height: itemHeight
                )
            )
            documentView.addSubview(itemView)
        }
        
        scrollView.documentView = documentView
        contentView.addSubview(scrollView)
    }
    
    private func setupStaticContent(contentView: NSView, windowDimensions: (width: CGFloat, height: CGFloat)) {
        let itemHeight: CGFloat = 60
        
        // Add clipboard items directly (no scrolling needed)
        for (index, item) in clipboardItems.enumerated() {
            let itemView = createItemView(
                item: item,
                index: index,
                frame: NSRect(
                    x: 0,
                    y: windowDimensions.height - CGFloat(index + 1) * itemHeight,
                    width: windowDimensions.width,
                    height: itemHeight
                )
            )
            contentView.addSubview(itemView)
        }
    }
    
    private func showAndConfigureWindow(timeout: Int) {
        guard let window = window else { return }
        
        // Show window and make it key to receive keyboard events
        window.makeKeyAndOrderFront(nil)
        
        // Set the first item view as first responder to enable keyboard navigation
        if let contentView = window.contentView {
            // Find the first ClipboardItemView and make it the first responder
            for subview in contentView.subviews {
                if let itemView = subview as? ClipboardItemView {
                    window.makeFirstResponder(itemView)
                    break
                }
                // Also check scroll view content
                if let scrollView = subview as? NSScrollView,
                   let documentView = scrollView.documentView {
                    for docSubview in documentView.subviews {
                        if let itemView = docSubview as? ClipboardItemView {
                            window.makeFirstResponder(itemView)
                            break
                        }
                    }
                }
            }
        }
        
        // Start auto-hide timer with configurable timeout (will be managed by mouse tracking)
        startAutoHideTimer(timeout: timeout)
        
        // Hide when clicking outside or pressing Escape
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            if event.type == .keyDown && event.keyCode == 53 { // Escape key
                self?.hide()
            } else if event.type == .leftMouseDown || event.type == .rightMouseDown {
                self?.hide()
            }
        }
    }
    
    private func startAutoHideTimer(timeout: Int) {
        autoHideTimer?.invalidate()
        
        // Don't start timer if timeout is 0 (never auto-hide)
        guard timeout > 0 else { return }
        
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout), repeats: false) { [weak self] _ in
            if self?.isMouseInside == false {
                self?.hide()
            }
        }
    }
    
    private func pauseAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    private func resumeAutoHideTimer() {
        if autoHideTimer == nil && !isMouseInside {
            startAutoHideTimer(timeout: currentTimeout)
        }
    }
    
    func mouseEnteredPopup() {
        isMouseInside = true
        pauseAutoHideTimer()
    }
    
    func mouseExitedPopup() {
        isMouseInside = false
        resumeAutoHideTimer()
    }
    
    private func createItemView(item: String, index: Int, frame: NSRect) -> ClipboardItemView {
        let containerView = ClipboardItemView(frame: frame)
        containerView.index = index
        containerView.popup = self
        containerView.isCurrentClipboardItem = (item == currentClipboardItem)
        containerView.isPinnedItem = isPinnedMode
        
        addSeparatorIfNeeded(to: containerView, index: index, frame: frame)
        styleContainerView(containerView, isCurrentItem: containerView.isCurrentClipboardItem)
        addLabelsToContainer(containerView, item: item, frame: frame)
        
        return containerView
    }
    
    private func addSeparatorIfNeeded(to containerView: ClipboardItemView, index: Int, frame: NSRect) {
        // Add border between items
        if index > 0 {
            let separator = NSView(
                frame: NSRect(x: 10, y: frame.height - 1, width: frame.width - 20, height: 1)
            )
            separator.wantsLayer = true
            separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
            containerView.addSubview(separator)
        }
    }
    
    private func styleContainerView(_ containerView: ClipboardItemView, isCurrentItem: Bool) {
        // Add background for better visibility
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        containerView.layer?.borderWidth = 0.5
    }
    
    private func addLabelsToContainer(_ containerView: ClipboardItemView, item: String, frame: NSRect) {
        // Clean up text for display - replace newlines with spaces and truncate
        let displayText = item.cleanedForDisplay().truncated(to: 50) // Reduced to make room for index
        
        // Create index label (1, 2, 3, etc.)
        let indexLabel = NSTextField(labelWithString: "\(containerView.index + 1)")
        indexLabel.font = NSFont.boldSystemFont(ofSize: 16)
        indexLabel.textColor = NSColor.systemBlue
        indexLabel.backgroundColor = NSColor.clear
        indexLabel.frame = NSRect(x: 8, y: 25, width: 25, height: 20)
        indexLabel.alignment = .center
        indexLabel.isBordered = false
        containerView.addSubview(indexLabel)
        
        // Create text label (adjusted for index)
        let label = NSTextField(labelWithString: displayText)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor.labelColor
        label.frame = NSRect(x: 35, y: 25, width: frame.width - 45, height: 20)
        label.lineBreakMode = .byTruncatingTail
        label.backgroundColor = NSColor.clear
        label.isBordered = false
        containerView.addSubview(label)
        
        // Add current clipboard indicator if this item is current
        if containerView.isCurrentClipboardItem {
            let currentIndicator = NSTextField(labelWithString: "●")
            currentIndicator.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            currentIndicator.textColor = NSColor(red: 0.0, green: 0.784, blue: 0.588, alpha: 1.0) // Mint green #00C896
            currentIndicator.frame = NSRect(x: frame.width - 25, y: 25, width: 15, height: 20)
            currentIndicator.alignment = .center
            currentIndicator.backgroundColor = NSColor.clear
            currentIndicator.isBordered = false
            containerView.addSubview(currentIndicator)
        }
        
        // Add click instruction with dynamic hotkey info
        let instructionText = containerView.index < 9 ? 
            "Click: paste • Hover: copy • \(containerView.index + 1): paste • ⌘⌥\(containerView.index + 1): instant • ↑/↓: navigate" :
            "Click: paste • Hover: copy • ↑/↓: navigate • ⌘+click: full text"
        let instructionLabel = NSTextField(labelWithString: instructionText)
        instructionLabel.font = NSFont.systemFont(ofSize: 9)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        instructionLabel.frame = NSRect(x: 35, y: 5, width: frame.width - 45, height: 12)
        instructionLabel.backgroundColor = NSColor.clear
        instructionLabel.isBordered = false
        containerView.addSubview(instructionLabel)
    }

}

// MARK: - String Extensions
public extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
    
    func cleanedForDisplay() -> String {
        return self.replacingOccurrences(of: "\n", with: " ")
                   .replacingOccurrences(of: "\r", with: " ")
                   .replacingOccurrences(of: "\t", with: " ")
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 
