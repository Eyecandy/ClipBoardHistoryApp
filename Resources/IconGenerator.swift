#!/usr/bin/env swift

import Foundation
import AppKit

func createAppIcon() {
    let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
    
    for size in sizes {
        let image = createClipboardIcon(size: size)
        let data = image.tiffRepresentation!
        let bitmap = NSBitmapImageRep(data: data)!
        let pngData = bitmap.representation(using: .png, properties: [:])!
        
        let filename = "icon_\(Int(size))x\(Int(size)).png"
        let url = URL(fileURLWithPath: filename)
        try! pngData.write(to: url)
        print("Created \(filename)")
    }
}

func createClipboardIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    // Clear background
    context.clear(CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    
    // Scale factors
    let scale = size / 64.0
    
    // Draw gradient background circle
    let backgroundRect = CGRect(x: size * 0.1, y: size * 0.1, width: size * 0.8, height: size * 0.8)
    
    // Create gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor.systemBlue.withAlphaComponent(0.8).cgColor,
        NSColor.systemBlue.withAlphaComponent(0.4).cgColor
    ]
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
    
    // Draw gradient background
    context.saveGState()
    context.addEllipse(in: backgroundRect)
    context.clip()
    context.drawLinearGradient(gradient, 
                              start: CGPoint(x: backgroundRect.minX, y: backgroundRect.maxY),
                              end: CGPoint(x: backgroundRect.maxX, y: backgroundRect.minY),
                              options: [])
    context.restoreGState()
    
    // Draw clipboard main body
    let clipboardRect = CGRect(
        x: size * 0.25,
        y: size * 0.15,
        width: size * 0.5,
        height: size * 0.65
    )
    
    context.setFillColor(NSColor.white.cgColor)
    context.setStrokeColor(NSColor.darkGray.cgColor)
    context.setLineWidth(2.0 * scale)
    
    // Rounded rectangle for clipboard
    let path = CGPath(roundedRect: clipboardRect, cornerWidth: 4 * scale, cornerHeight: 4 * scale, transform: nil)
    context.addPath(path)
    context.drawPath(using: .fillStroke)
    
    // Draw clipboard clip at top
    let clipRect = CGRect(
        x: size * 0.4,
        y: size * 0.72,
        width: size * 0.2,
        height: size * 0.08
    )
    
    context.setFillColor(NSColor.systemGray.cgColor)
    context.setStrokeColor(NSColor.darkGray.cgColor)
    context.setLineWidth(1.5 * scale)
    
    let clipPath = CGPath(roundedRect: clipRect, cornerWidth: 2 * scale, cornerHeight: 2 * scale, transform: nil)
    context.addPath(clipPath)
    context.drawPath(using: .fillStroke)
    
    // Draw text lines on clipboard
    context.setStrokeColor(NSColor.systemBlue.cgColor)
    context.setLineWidth(1.5 * scale)
    
    let lineSpacing = size * 0.08
    let startY = size * 0.6
    let leftMargin = size * 0.32
    let rightMargin = size * 0.68
    
    for i in 0..<4 {
        let y = startY - CGFloat(i) * lineSpacing
        let lineWidth = (i == 3) ? size * 0.25 : size * 0.36 // Last line shorter
        
        context.move(to: CGPoint(x: leftMargin, y: y))
        context.addLine(to: CGPoint(x: leftMargin + lineWidth, y: y))
        context.strokePath()
    }
    
    // Add a small highlight/shine effect
    context.setFillColor(NSColor.white.withAlphaComponent(0.3).cgColor)
    let highlightRect = CGRect(
        x: size * 0.28,
        y: size * 0.5,
        width: size * 0.15,
        height: size * 0.25
    )
    let highlightPath = CGPath(ellipseIn: highlightRect, transform: nil)
    context.addPath(highlightPath)
    context.fillPath()
    
    image.unlockFocus()
    
    return image
}

// Generate the icons
createAppIcon()
print("App icons generated successfully!") 