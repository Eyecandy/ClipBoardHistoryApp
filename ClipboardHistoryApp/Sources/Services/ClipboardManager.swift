import Foundation
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    @Published var clipboardItems: [ClipboardItem] = []
    private var timer: Timer?
    private let maxItems = 50
    private let pasteboard = NSPasteboard.general
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Check clipboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard let string = pasteboard.string(forType: .string) else { return }
        
        // Check if this is a new item
        if let lastItem = clipboardItems.first, lastItem.content == string {
            return
        }
        
        // Create new clipboard item
        let newItem = ClipboardItem(content: string, timestamp: Date())
        
        // Add to history
        DispatchQueue.main.async {
            self.clipboardItems.insert(newItem, at: 0)
            
            // Keep only the last maxItems
            if self.clipboardItems.count > self.maxItems {
                self.clipboardItems.removeLast()
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
    }
    
    func clearHistory() {
        clipboardItems.removeAll()
    }
} 