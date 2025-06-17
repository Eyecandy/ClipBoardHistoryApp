import Foundation
import AppKit

public protocol ClipboardManagerDelegate: AnyObject {
    func clipboardDidChange()
}

public class ClipboardManager {
    public weak var delegate: ClipboardManagerDelegate?
    private var clipboardHistory: [String] = []
    private var pinnedItems: [String] = []
    private var timer: Timer?
    private var lastClipboardContent: String = ""
    private let maxHistorySize = 20
    private let maxPinnedSize = 10
    
    private let pasteboard = NSPasteboard.general
    private let historyKey = "ClipboardHistory"
    private let pinnedKey = "ClipboardPinned"
    private let popupItemCountKey = "PopupItemCount"
    private let defaultPopupItemCount = 3
    
    public init() {}
    
    public func startMonitoring() {
        // Load saved history from UserDefaults
        loadHistory()
        loadPinnedItems()
        
        // Get initial clipboard content safely
        if let initialContent = getCurrentClipboardContent() {
            lastClipboardContent = initialContent
        }
        
        // Start timer to check clipboard changes every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func getCurrentClipboardContent() -> String? {
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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
        
        // Save history to persistent storage
        saveHistory()
        
        delegate?.clipboardDidChange()
    }
    
    public func getHistory() -> [String] {
        return clipboardHistory
    }
    
    public func getPinnedItems() -> [String] {
        return pinnedItems
    }
    
    public func getCurrentClipboardItem() -> String? {
        return getCurrentClipboardContent()
    }
    
    public func copyToClipboard(_ content: String) {
        guard !content.isEmpty else { return }
        
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastClipboardContent = content
        
        // Move selected item to top of history
        clipboardHistory.removeAll { $0 == content }
        clipboardHistory.insert(content, at: 0)
        
        // Keep only the most recent items
        if clipboardHistory.count > maxHistorySize {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistorySize))
        }
        
        // Save updated history
        saveHistory()
        
        delegate?.clipboardDidChange()
    }
    
    public func copySelectedItem(_ content: String) {
        guard !content.isEmpty else { return }
        
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastClipboardContent = content
        
        // DON'T add to history - this is a recall from existing history
        // Just update the last clipboard content to prevent duplicate detection
    }
    
    public func copyAndPasteItem(_ content: String) {
        guard !content.isEmpty else { return }
        
        // First copy to clipboard
        copySelectedItem(content)
        
        // Then simulate paste (Cmd+V)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        // Create key event for Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down for V with Cmd modifier
        if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            keyDownEvent.flags = .maskCommand
            keyDownEvent.post(tap: .cghidEventTap)
        }
        
        // Key up for V
        if let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }
    
    public func pinItem(_ content: String) {
        guard !content.isEmpty else { return }
        
        // Remove if already pinned (to move to top)
        pinnedItems.removeAll { $0 == content }
        
        // Add to beginning of pinned items
        pinnedItems.insert(content, at: 0)
        
        // Keep only the max pinned items
        if pinnedItems.count > maxPinnedSize {
            pinnedItems = Array(pinnedItems.prefix(maxPinnedSize))
        }
        
        savePinnedItems()
        delegate?.clipboardDidChange()
    }
    
    public func unpinItem(_ content: String) {
        pinnedItems.removeAll { $0 == content }
        savePinnedItems()
        delegate?.clipboardDidChange()
    }
    
    public func isPinned(_ content: String) -> Bool {
        return pinnedItems.contains(content)
    }
    
    public func clearHistory() {
        clipboardHistory.removeAll()
        saveHistory() // Save the empty history
    }
    
    public func clearPinnedItems() {
        pinnedItems.removeAll()
        savePinnedItems()
    }
    
    public func deleteItem(at index: Int) {
        guard index >= 0 && index < clipboardHistory.count else { return }
        clipboardHistory.remove(at: index)
        saveHistory()
        delegate?.clipboardDidChange()
    }
    
    public func deletePinnedItem(at index: Int) {
        guard index >= 0 && index < pinnedItems.count else { return }
        pinnedItems.remove(at: index)
        savePinnedItems()
        delegate?.clipboardDidChange()
    }
    
    // MARK: - Popup Item Count Configuration
    
    public func getPopupItemCount() -> Int {
        let count = UserDefaults.standard.integer(forKey: popupItemCountKey)
        // Return default if not set, otherwise validate range
        return count == 0 ? defaultPopupItemCount : max(1, min(20, count))
    }
    
    public func setPopupItemCount(_ count: Int) {
        let validatedCount = max(1, min(20, count))
        UserDefaults.standard.set(validatedCount, forKey: popupItemCountKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        UserDefaults.standard.set(clipboardHistory, forKey: historyKey)
    }
    
    private func loadHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: historyKey) as? [String] {
            clipboardHistory = savedHistory
            print("📚 Loaded \(clipboardHistory.count) items from saved history")
            
            // Trigger UI update after loading history
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.clipboardDidChange()
            }
        }
    }
    
    private func savePinnedItems() {
        UserDefaults.standard.set(pinnedItems, forKey: pinnedKey)
        UserDefaults.standard.synchronize()
    }
    
    private func loadPinnedItems() {
        if let savedPinned = UserDefaults.standard.array(forKey: pinnedKey) as? [String] {
            pinnedItems = savedPinned
            print("📌 Loaded \(pinnedItems.count) pinned items")
        }
    }
    
    public func saveHistoryOnExit() {
        UserDefaults.standard.set(clipboardHistory, forKey: historyKey)
        UserDefaults.standard.set(pinnedItems, forKey: pinnedKey)
        UserDefaults.standard.synchronize() // Force immediate save
        print("💾 History and pinned items saved on app exit")
    }
} 
