import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardItems
        }
        return clipboardManager.clipboardItems.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            // Clipboard history list
            List(filteredItems) { item in
                ClipboardItemRow(item: item)
                    .onTapGesture {
                        clipboardManager.copyToClipboard(item)
                    }
            }
            
            // Clear button
            Button(action: {
                clipboardManager.clearHistory()
            }) {
                Text("Clear History")
                    .foregroundColor(.red)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.content)
                .lineLimit(2)
                .font(.system(size: 14))
            
            Text(item.formattedTime)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
} 