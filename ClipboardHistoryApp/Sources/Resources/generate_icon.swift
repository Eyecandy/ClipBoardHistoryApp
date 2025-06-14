import AppKit
import SwiftUI

struct IconGenerator {
    static func main() async {
        // Create a 1024x1024 image
        let size = CGSize(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: 
            Image(systemName: "doc.on.clipboard")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 800, height: 800)
                .foregroundColor(.white)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 200))
        )
        renderer.scale = 1

        // Generate different sizes
        let sizes = [
            (16, "1x"),
            (32, "2x"),
            (32, "1x"),
            (64, "2x"),
            (128, "1x"),
            (256, "2x"),
            (256, "1x"),
            (512, "2x"),
            (512, "1x"),
            (1024, "2x")
        ]

        for (size, scale) in sizes {
            let filename = "icon_\(size)x\(size)\(scale == "2x" ? "@2x" : "").png"
            let path = "ClipboardHistoryApp/Sources/Resources/Assets.xcassets/AppIcon.appiconset/\(filename)"
            
            if let image = renderer.nsImage {
                let resizedImage = NSImage(size: NSSize(width: size, height: size))
                resizedImage.lockFocus()
                image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
                resizedImage.unlockFocus()
                
                if let tiffData = resizedImage.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: URL(fileURLWithPath: path))
                }
            }
        }
    }
} 