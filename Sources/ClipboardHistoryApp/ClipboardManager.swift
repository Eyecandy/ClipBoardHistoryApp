import Foundation
import AppKit

protocol ClipboardManagerDelegate: AnyObject {
    func clipboardDidChange()
}

class ClipboardManager {
    weak var delegate: ClipboardManagerDelegate?
    private var clipboardHistory: [String] = []
    private var timer: Timer?
    private var lastClipboardContent: String = ""
    private let maxHistorySize = 20
    
    private let pasteboard = NSPasteboard.general
    
    func startMonitoring() {
        // Get initial clipboard content safely
        if let initialContent = getCurrentClipboardContent() {
            lastClipboardContent = initialContent
        }
        
        // Start timer to check clipboard changes every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func getCurrentClipboardContent() -> String? {
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty,
              content.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
            return nil
        }
        return content
    }
    
    private func checkClipboardChanges() {
        guard let currentContent = getCurrentClipboardContent(),
              currentContent != lastClipboardContent else {
            return
        }
        
        // Remove if already exists (to move it to top)
        clipboardHistory.removeAll { $0 == currentContent }
        
        // Add to beginning of history
        clipboardHistory.insert(currentContent, at: 0)
        
        // Keep only the most recent items
        if clipboardHistory.count > maxHistorySize {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistorySize))
        }
        
        lastClipboardContent = currentContent
        delegate?.clipboardDidChange()
    }
    
    func getHistory() -> [String] {
        return clipboardHistory
    }
    
    func copyToClipboard(_ content: String) {
        guard !content.isEmpty else { return }
        
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastClipboardContent = content
        
        // Move selected item to top of history
        clipboardHistory.removeAll { $0 == content }
        clipboardHistory.insert(content, at: 0)
        
        delegate?.clipboardDidChange()
    }
    
    func copySelectedItem(_ content: String) {
        guard !content.isEmpty else { return }
        
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastClipboardContent = content
        
        // DON'T add to history - this is a recall from existing history
        // Just update the last clipboard content to prevent duplicate detection
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
    }
} 