import Foundation
import AppKit

public protocol ClipboardManagerDelegate: AnyObject {
    func clipboardDidChange()
}

public class ClipboardManager {
    public weak var delegate: ClipboardManagerDelegate?
    private var clipboardHistory: [String] = []
    private var timer: Timer?
    private var lastClipboardContent: String = ""
    private let maxHistorySize = 20
    
    private let pasteboard = NSPasteboard.general
    private let historyKey = "ClipboardHistory"
    private let popupItemCountKey = "PopupItemCount"
    private let defaultPopupItemCount = 3
    
    public init() {}
    
    public func startMonitoring() {
        // Load saved history from UserDefaults
        loadHistory()
        
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
    
    public func clearHistory() {
        clipboardHistory.removeAll()
        saveHistory() // Save the empty history
    }
    
    public func deleteItem(at index: Int) {
        guard index >= 0 && index < clipboardHistory.count else { return }
        clipboardHistory.remove(at: index)
        saveHistory()
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
    
    public func saveHistoryOnExit() {
        UserDefaults.standard.set(clipboardHistory, forKey: historyKey)
        UserDefaults.standard.synchronize() // Force immediate save
        print("💾 History saved on app exit")
    }
} 
