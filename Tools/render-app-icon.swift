// Renders the TeaShot app icon (design track E: half-empty glass shot cup) to a 1024 px PNG.
// Usage: swift Tools/render-app-icon.swift <output.png>
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png")
let canvas = 1024
// macOS icon grid: an 824 pt rounded body centred on a 1024 canvas, leaving room for the shadow.
let bodyOrigin = 100.0
let scale = 824.0 / 100.0

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func gradient(_ top: UInt32, _ bottom: UInt32) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [color(top), color(bottom)] as CFArray, locations: [0, 1])!
}

func cupOutline() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 28.5, y: 29.5))
    path.addLine(to: CGPoint(x: 65.5, y: 29.5))
    path.addLine(to: CGPoint(x: 62.8, y: 70.2))
    path.addQuadCurve(to: CGPoint(x: 53.6, y: 78.5), control: CGPoint(x: 61.8, y: 78.5))
    path.addLine(to: CGPoint(x: 40.4, y: 78.5))
    path.addQuadCurve(to: CGPoint(x: 31.2, y: 70.2), control: CGPoint(x: 32.2, y: 78.5))
    path.closeSubpath()
    return path
}

func cupInterior() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 31.8, y: 33))
    path.addLine(to: CGPoint(x: 62.2, y: 33))
    path.addLine(to: CGPoint(x: 59.8, y: 69.6))
    path.addQuadCurve(to: CGPoint(x: 53.4, y: 75.2), control: CGPoint(x: 59.1, y: 75.2))
    path.addLine(to: CGPoint(x: 40.6, y: 75.2))
    path.addQuadCurve(to: CGPoint(x: 34.2, y: 69.6), control: CGPoint(x: 34.9, y: 75.2))
    path.closeSubpath()
    return path
}

let context = CGContext(
    data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
// Work in the 100-unit, y-down space of the design SVG.
context.translateBy(x: 0, y: CGFloat(canvas))
context.scaleBy(x: 1, y: -1)
context.translateBy(x: bodyOrigin, y: bodyOrigin)
context.scaleBy(x: scale, y: scale)

let body = CGPath(roundedRect: CGRect(x: 0, y: 0, width: 100, height: 100), cornerWidth: 22.5, cornerHeight: 22.5, transform: nil)

context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: 1.2), blur: 3, color: color(0x000000, 0.3))
context.addPath(body)
context.setFillColor(color(0x2C5530))
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(body)
context.clip()
context.drawLinearGradient(gradient(0x5F8E3B, 0x2C5530), start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 100), options: [])
context.restoreGState()

context.setFillColor(color(0xFFFFFF, 0.22))
context.fillEllipse(in: CGRect(x: 47 - 27, y: 83.5 - 3.6, width: 54, height: 7.2))

let handle = CGMutablePath()
handle.move(to: CGPoint(x: 65, y: 40))
handle.addQuadCurve(to: CGPoint(x: 77.8, y: 51.5), control: CGPoint(x: 78.5, y: 40))
handle.addQuadCurve(to: CGPoint(x: 63, y: 62.5), control: CGPoint(x: 77, y: 62.5))
context.addPath(handle)
context.setStrokeColor(color(0xFFFFFF, 0.92))
context.setLineWidth(3.4)
context.setLineCap(.round)
context.strokePath()

context.addPath(cupOutline())
context.setFillColor(color(0xFFFFFF, 0.15))
context.fillPath()

let teaSurface = 56.0
context.saveGState()
context.addPath(cupInterior())
context.clip()
context.drawLinearGradient(gradient(0xDDEDAA, 0xB0D06C), start: CGPoint(x: 0, y: teaSurface), end: CGPoint(x: 0, y: 80), options: [])
context.restoreGState()
context.saveGState()
context.addPath(cupInterior())
context.clip()
context.move(to: CGPoint(x: 28, y: teaSurface))
context.addLine(to: CGPoint(x: 68, y: teaSurface))
context.setStrokeColor(color(0xFFFFFF, 0.75))
context.setLineWidth(1.6)
context.strokePath()
context.restoreGState()

context.addPath(cupOutline())
context.setStrokeColor(color(0xFFFFFF, 0.95))
context.setLineWidth(2.6)
context.setLineJoin(.round)
context.strokePath()

context.move(to: CGPoint(x: 35, y: 34))
context.addLine(to: CGPoint(x: 35, y: 56))
context.setStrokeColor(color(0xFFFFFF, 0.45))
context.setLineWidth(2.4)
context.setLineCap(.round)
context.strokePath()

let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: output)
print("Wrote \(output.path)")
