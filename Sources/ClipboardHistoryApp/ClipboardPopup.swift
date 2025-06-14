import Foundation
import AppKit

protocol ClipboardPopupDelegate: AnyObject {
    func popupDidSelectItem(_ item: String)
}

// Custom view class to handle mouse events and store index
class ClipboardItemView: NSView {
    var index: Int = 0
    weak var popup: ClipboardPopup?
    
    override func mouseEntered(with event: NSEvent) {
        wantsLayer = true
        layer?.backgroundColor = NSColor.selectedControlColor.withAlphaComponent(0.3).cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func rightMouseDown(with event: NSEvent) {
        popup?.itemRightClicked(at: index)
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
}

class ClipboardPopup: NSObject {
    weak var delegate: ClipboardPopupDelegate?
    private var window: NSWindow?
    private var clipboardItems: [String] = []
    private var eventMonitor: Any?
    
    func show(with items: [String]) {
        hide() // Hide any existing popup
        
        clipboardItems = Array(items.prefix(3)) // Only show top 3 items
        guard !clipboardItems.isEmpty else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        createWindow(at: mouseLocation)
    }
    
    func hide() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }
    
    func itemRightClicked(at index: Int) {
        guard index < clipboardItems.count else { return }
        let selectedItem = clipboardItems[index]
        delegate?.popupDidSelectItem(selectedItem)
        hide()
    }
    
    private func createWindow(at location: NSPoint) {
        let itemHeight: CGFloat = 40
        let windowWidth: CGFloat = 300
        let windowHeight = CGFloat(clipboardItems.count) * itemHeight
        
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
        
        let windowRect = NSRect(
            x: windowOrigin.x,
            y: windowOrigin.y,
            width: windowWidth,
            height: windowHeight
        )
        
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { return }
        
        window.level = .floating
        window.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        window.hasShadow = true
        window.isOpaque = false
        
        // Create content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        window.contentView = contentView
        
        // Add clipboard items
        for (index, item) in clipboardItems.enumerated() {
            let itemView = createItemView(
                item: item,
                index: index,
                frame: NSRect(
                    x: 0,
                    y: windowHeight - CGFloat(index + 1) * itemHeight,
                    width: windowWidth,
                    height: itemHeight
                )
            )
            contentView.addSubview(itemView)
        }
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.hide()
        }
        
        // Hide when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }
    
    private func createItemView(item: String, index: Int, frame: NSRect) -> ClipboardItemView {
        let containerView = ClipboardItemView(frame: frame)
        containerView.index = index
        containerView.popup = self
        
        // Add border between items
        if index > 0 {
            let separator = NSView(frame: NSRect(x: 10, y: frame.height - 1, width: frame.width - 20, height: 1))
            separator.wantsLayer = true
            separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
            containerView.addSubview(separator)
        }
        
        // Truncate long text
        let displayText = item.truncated(to: 50)
        
        // Create label
        let label = NSTextField(labelWithString: displayText)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = NSColor.labelColor
        label.frame = NSRect(x: 15, y: 8, width: frame.width - 30, height: 24)
        label.lineBreakMode = .byTruncatingTail
        containerView.addSubview(label)
        
        return containerView
    }
} 