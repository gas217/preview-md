#!/usr/bin/env swift
// Generates PreviewMD app icon as PNG files at all required macOS sizes.
// Run: swift scripts/generate-icon.swift
// Output: Resources/AppIcon.iconset/*.png

import Cocoa

let outputDir = "Resources/AppIcon.iconset"
try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// macOS icon sizes: (filename, pixel size)
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func drawIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext

    // --- Background: rounded rect with gradient ---
    let cornerRadius = s * 0.22 // macOS icon corner radius
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient: deep blue to purple (reminiscent of markdown/code editors)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.15, green: 0.10, blue: 0.35, alpha: 1.0),  // deep purple
        CGColor(red: 0.08, green: 0.20, blue: 0.45, alpha: 1.0),  // deep blue
    ]
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])

    // --- "MD" text: bold, white, centered ---
    let fontSize = s * 0.38
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let text = "MD"
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let textSize = attrStr.size()
    let textX = (s - textSize.width) / 2
    let textY = (s - textSize.height) / 2 + s * 0.05 // nudge up slightly for visual center
    attrStr.draw(at: NSPoint(x: textX, y: textY))

    // --- Subtle "preview eye" accent: a small eye-like shape below MD ---
    let eyeY = s * 0.22
    let eyeW = s * 0.28
    let eyeH = s * 0.08
    let eyeX = (s - eyeW) / 2

    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 0.7))
    ctx.setLineWidth(max(s * 0.015, 1.0))

    // Eye outline: two arcs
    let eyePath = CGMutablePath()
    eyePath.move(to: CGPoint(x: eyeX, y: eyeY))
    eyePath.addQuadCurve(to: CGPoint(x: eyeX + eyeW, y: eyeY),
                         control: CGPoint(x: eyeX + eyeW / 2, y: eyeY + eyeH))
    eyePath.addQuadCurve(to: CGPoint(x: eyeX, y: eyeY),
                         control: CGPoint(x: eyeX + eyeW / 2, y: eyeY - eyeH))
    ctx.addPath(eyePath)
    ctx.strokePath()

    // Pupil dot
    let pupilR = s * 0.025
    let pupilCenter = CGPoint(x: s / 2, y: eyeY)
    ctx.setFillColor(CGColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 0.7))
    ctx.fillEllipse(in: CGRect(x: pupilCenter.x - pupilR, y: pupilCenter.y - pupilR,
                                width: pupilR * 2, height: pupilR * 2))

    img.unlockFocus()
    return img
}

for (name, px) in sizes {
    let img = drawIcon(size: px)
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: failed to render \(name)")
        continue
    }
    let path = "\(outputDir)/\(name)"
    try png.write(to: URL(fileURLWithPath: path))
    print("Wrote \(path) (\(px)x\(px))")
}

print("Done. Run: iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns")
