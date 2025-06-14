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
        print("Mouse entered item \(index)")
        wantsLayer = true
        layer?.backgroundColor = NSColor.selectedControlColor.withAlphaComponent(0.3).cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        print("Mouse exited item \(index)")
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        print("🖱️ Left click detected on item \(index)")
        popup?.itemClicked(at: index)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        print("🖱️ Right click detected on item \(index)")
        popup?.itemClicked(at: index)
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
        print("📱 Showing popup with \(items.count) items")
        hide() // Hide any existing popup
        
        clipboardItems = Array(items.prefix(3)) // Only show top 3 items
        guard !clipboardItems.isEmpty else { 
            print("❌ No items to show")
            return 
        }
        
        let mouseLocation = NSEvent.mouseLocation
        print("📍 Mouse location: \(mouseLocation)")
        createWindow(at: mouseLocation)
    }
    
    func hide() {
        print("🙈 Hiding popup")
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }
    
    func itemClicked(at index: Int) {
        print("🎯 Item \(index) clicked!")
        guard index < clipboardItems.count else { 
            print("❌ Invalid index \(index), only have \(clipboardItems.count) items")
            return 
        }
        let selectedItem = clipboardItems[index]
        print("✅ Selected: \(selectedItem)")
        delegate?.popupDidSelectItem(selectedItem)
        hide()
    }
    
    private func createWindow(at location: NSPoint) {
        let itemHeight: CGFloat = 50 // Make items taller for easier clicking
        let windowWidth: CGFloat = 300
        let windowHeight = CGFloat(clipboardItems.count) * itemHeight
        
        print("📏 Creating window: width=\(windowWidth), height=\(windowHeight)")
        
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
        
        print("📍 Final window position: \(windowRect)")
        
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { 
            print("❌ Failed to create window")
            return 
        }
        
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
            print("📝 Added item \(index): \(item)")
        }
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        print("✅ Window shown")
        
        // Auto-hide after 10 seconds (increased time for testing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            print("⏰ Auto-hiding popup after timeout")
            self?.hide()
        }
        
        // Hide when clicking outside (but not inside the popup)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            print("🖱️ Global click detected at \(event.locationInWindow)")
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
        
        // Add background for better visibility
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        containerView.layer?.borderWidth = 0.5
        
        // Truncate long text
        let displayText = item.truncated(to: 50)
        
        // Create label
        let label = NSTextField(labelWithString: displayText)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor.labelColor
        label.frame = NSRect(x: 15, y: 12, width: frame.width - 30, height: 26)
        label.lineBreakMode = .byTruncatingTail
        label.backgroundColor = NSColor.clear
        label.isBordered = false
        containerView.addSubview(label)
        
        // Add click instruction
        let instructionLabel = NSTextField(labelWithString: "Click to paste")
        instructionLabel.font = NSFont.systemFont(ofSize: 10)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        instructionLabel.frame = NSRect(x: 15, y: 2, width: frame.width - 30, height: 12)
        instructionLabel.backgroundColor = NSColor.clear
        instructionLabel.isBordered = false
        containerView.addSubview(instructionLabel)
        
        print("🏗️ Created item view for index \(index) with frame \(frame)")
        
        return containerView
    }
} 