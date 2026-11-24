// Renders the README brand visuals (hero banner and glyph strip, light and dark) as @2x PNGs.
// Usage: swift docs/brand/render-brand.swift <repo root>
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
let outputDirectory = root.appendingPathComponent("docs/brand")
let iconURL = root.appendingPathComponent("TeaShot/Assets.xcassets/AppIcon.appiconset/icon_1024.png")
let pixelScale = 2.0

struct Theme {
    let name: String
    let background: UInt32
    let border: UInt32
    let text: UInt32
    let secondary: UInt32
    let accent: UInt32
    let stroke: UInt32
    let glass: CGFloat
    let teaTop: UInt32
    let teaBottom: UInt32
}

let themes = [
    Theme(
        name: "light", background: 0xF6F3EA, border: 0xE4DFD0, text: 0x1C2119, secondary: 0x4A5145,
        accent: 0x4F7D2F, stroke: 0x2E5A2F, glass: 0.08, teaTop: 0xC9E28A, teaBottom: 0x9CC46B),
    Theme(
        name: "dark", background: 0x1B2219, border: 0x2E3A2B, text: 0xF2F4EE, secondary: 0xB7BFB0,
        accent: 0x9CC46B, stroke: 0xF2F4EE, glass: 0.10, teaTop: 0xDDEDAA, teaBottom: 0xB0D06C),
]

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func render(_ name: String, width: Double, height: Double, draw: (CGContext) -> Void) throws {
    let context = CGContext(
        data: nil, width: Int(width * pixelScale), height: Int(height * pixelScale), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.translateBy(x: 0, y: height * pixelScale)
    context.scaleBy(x: pixelScale, y: -pixelScale)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    draw(context)
    let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    let url = outputDirectory.appendingPathComponent(name)
    try png.write(to: url)
    print("Wrote \(url.path)")
}

func card(_ context: CGContext, _ theme: Theme, width: Double, height: Double, radius: Double) {
    let rect = CGRect(x: 0.5, y: 0.5, width: width - 1, height: height - 1)
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.addPath(path)
    context.setFillColor(color(theme.background).cgColor)
    context.fillPath()
    context.addPath(path)
    context.setStrokeColor(color(theme.border).cgColor)
    context.setLineWidth(1)
    context.strokePath()
}

@discardableResult
func text(_ string: String, x: Double, y: Double, font: NSFont, color: NSColor, kern: Double = 0, centered: Bool = false) -> CGSize {
    let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color, .kern: kern])
    let size = attributed.size()
    attributed.draw(at: NSPoint(x: centered ? x - size.width / 2 : x, y: y))
    return size
}

// Glass cup of the app icon, in its 100-unit design space. `level` is 0...1.
func glassCup(_ context: CGContext, _ theme: Theme, x: Double, y: Double, scale: Double, level: Double) {
    context.saveGState()
    context.translateBy(x: x - 28.5 * scale, y: y - 29.5 * scale)
    context.scaleBy(x: scale, y: scale)

    let outline = CGMutablePath()
    outline.move(to: CGPoint(x: 28.5, y: 29.5))
    outline.addLine(to: CGPoint(x: 65.5, y: 29.5))
    outline.addLine(to: CGPoint(x: 62.8, y: 70.2))
    outline.addQuadCurve(to: CGPoint(x: 53.6, y: 78.5), control: CGPoint(x: 61.8, y: 78.5))
    outline.addLine(to: CGPoint(x: 40.4, y: 78.5))
    outline.addQuadCurve(to: CGPoint(x: 31.2, y: 70.2), control: CGPoint(x: 32.2, y: 78.5))
    outline.closeSubpath()

    let interior = CGMutablePath()
    interior.move(to: CGPoint(x: 31.8, y: 33))
    interior.addLine(to: CGPoint(x: 62.2, y: 33))
    interior.addLine(to: CGPoint(x: 59.8, y: 69.6))
    interior.addQuadCurve(to: CGPoint(x: 53.4, y: 75.2), control: CGPoint(x: 59.1, y: 75.2))
    interior.addLine(to: CGPoint(x: 40.6, y: 75.2))
    interior.addQuadCurve(to: CGPoint(x: 34.2, y: 69.6), control: CGPoint(x: 34.9, y: 75.2))
    interior.closeSubpath()

    let handle = CGMutablePath()
    handle.move(to: CGPoint(x: 65, y: 40))
    handle.addQuadCurve(to: CGPoint(x: 77.8, y: 51.5), control: CGPoint(x: 78.5, y: 40))
    handle.addQuadCurve(to: CGPoint(x: 63, y: 62.5), control: CGPoint(x: 77, y: 62.5))
    context.addPath(handle)
    context.setStrokeColor(color(theme.stroke).cgColor)
    context.setLineWidth(3.4)
    context.setLineCap(.round)
    context.strokePath()

    context.addPath(outline)
    context.setFillColor(color(theme.stroke, theme.glass).cgColor)
    context.fillPath()

    if level > 0 {
        let surface = 76 - 38 * level
        context.saveGState()
        context.addPath(interior)
        context.clip()
        let gradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
            colors: [color(theme.teaTop).cgColor, color(theme.teaBottom).cgColor] as CFArray, locations: [0, 1])!
        context.clip(to: CGRect(x: 0, y: surface, width: 100, height: 100))
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: surface), end: CGPoint(x: 0, y: 80), options: [.drawsAfterEndLocation])
        context.restoreGState()
    }

    context.addPath(outline)
    context.setStrokeColor(color(theme.stroke).cgColor)
    context.setLineWidth(2.6)
    context.setLineJoin(.round)
    context.strokePath()
    context.restoreGState()
}

// Menu bar glyph, same geometry as TeaShot/CupGlyph.swift (18-unit space).
func menuBarGlyph(_ context: CGContext, tint: NSColor, x: Double, y: Double, scale: Double, level: Double) {
    context.saveGState()
    context.translateBy(x: x, y: y)
    context.scaleBy(x: scale, y: scale)
    context.setStrokeColor(tint.cgColor)
    context.setFillColor(tint.cgColor)
    context.setLineWidth(1.4)
    context.setLineJoin(.round)
    context.setLineCap(.round)

    let cup = CGMutablePath()
    cup.move(to: CGPoint(x: 3.2, y: 4))
    cup.addLine(to: CGPoint(x: 12.8, y: 4))
    cup.addLine(to: CGPoint(x: 12.1, y: 13.2))
    cup.addQuadCurve(to: CGPoint(x: 9.6, y: 15.5), control: CGPoint(x: 11.9, y: 15.5))
    cup.addLine(to: CGPoint(x: 6.4, y: 15.5))
    cup.addQuadCurve(to: CGPoint(x: 3.9, y: 13.2), control: CGPoint(x: 4.1, y: 15.5))
    cup.closeSubpath()
    context.addPath(cup)
    context.strokePath()

    let handle = CGMutablePath()
    handle.move(to: CGPoint(x: 12.7, y: 6.4))
    handle.addQuadCurve(to: CGPoint(x: 15.5, y: 9.1), control: CGPoint(x: 15.7, y: 6.4))
    handle.addQuadCurve(to: CGPoint(x: 12.3, y: 11.6), control: CGPoint(x: 15.3, y: 11.6))
    context.addPath(handle)
    context.strokePath()

    if level > 0 {
        let tea = CGMutablePath()
        tea.move(to: CGPoint(x: 4.7, y: 6.2))
        tea.addLine(to: CGPoint(x: 11.3, y: 6.2))
        tea.addLine(to: CGPoint(x: 10.8, y: 13))
        tea.addQuadCurve(to: CGPoint(x: 9.5, y: 14.1), control: CGPoint(x: 10.7, y: 14.1))
        tea.addLine(to: CGPoint(x: 6.5, y: 14.1))
        tea.addQuadCurve(to: CGPoint(x: 5.2, y: 13), control: CGPoint(x: 5.3, y: 14.1))
        tea.closeSubpath()
        context.addPath(tea)
        context.clip()
        let surface = 14.1 - (14.1 - 6.2) * level
        context.fill(CGRect(x: 0, y: surface, width: 18, height: 18 - surface))
    }
    context.restoreGState()
}

let icon = NSImage(contentsOf: iconURL)!
let levels = [1.0, 0.75, 0.5, 0.25, 0.0]

for theme in themes {
    try render("hero-\(theme.name).png", width: 1280, height: 400) { context in
        card(context, theme, width: 1280, height: 400, radius: 32)
        icon.draw(
            in: NSRect(x: 56, y: 92, width: 216, height: 216), from: .zero, operation: .sourceOver, fraction: 1,
            respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high.rawValue])
        text("MACOS MENU BAR APP", x: 300, y: 118, font: .systemFont(ofSize: 15, weight: .semibold), color: color(theme.accent), kern: 1.4)
        text("TeaShot", x: 296, y: 138, font: .systemFont(ofSize: 84, weight: .bold), color: color(theme.text), kern: -2.2)
        text(
            "Keep your Mac awake while your agents work.", x: 300, y: 248,
            font: .systemFont(ofSize: 24, weight: .regular), color: color(theme.secondary))

        let scale = 1.2
        let pitch = 74.0
        let startX = 1280 - 64 - (pitch * 4 + 50 * scale)
        for (index, level) in levels.enumerated() {
            glassCup(context, theme, x: startX + Double(index) * pitch, y: 200 - 24.5 * scale, scale: scale, level: level)
        }
    }

    try render("glyph-steps-\(theme.name).png", width: 880, height: 176) { context in
        card(context, theme, width: 880, height: 176, radius: 24)
        let labels = ["Full", "¾", "½", "¼", "Empty"]
        let times = ["2:00", "1:30", "1:00", "0:30", nil]
        let column = 880.0 / 5
        for (index, level) in levels.enumerated() {
            let centre = column * (Double(index) + 0.5)
            let scale = 3.0
            let time = times[index]
            let font = NSFont.monospacedDigitSystemFont(ofSize: 29, weight: .medium)
            let timeWidth = time.map { NSAttributedString(string: $0, attributes: [.font: font]).size().width + 8 } ?? 0
            let glyphWidth = 18 * scale
            let left = centre - (glyphWidth + timeWidth) / 2
            menuBarGlyph(context, tint: color(theme.text), x: left, y: 42, scale: scale, level: level)
            if let time {
                text(time, x: left + glyphWidth + 6, y: 51, font: font, color: color(theme.text))
            }
            text(
                labels[index], x: centre, y: 116, font: .systemFont(ofSize: 17, weight: .medium), color: color(theme.secondary),
                centered: true)
        }
    }
}
