import AppKit

/// The menu bar glyph: a glass shot cup whose tea level shows the time left.
nonisolated enum CupGlyph {
    private static let cupSize: CGFloat = 18

    /// Quantizes progress to full, ¾, ½, ¼ or empty; any active time keeps at least a quarter.
    static func level(for progress: Double) -> Double {
        guard progress > 0 else { return 0 }
        return min(1, (progress * 4).rounded(.up) / 4)
    }

    static func image(level: Double) -> NSImage {
        let image = NSImage(size: NSSize(width: cupSize, height: cupSize), flipped: true) { _ in
            drawCup(level: level)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawCup(level: Double) {
        NSColor.black.set()

        let cup = NSBezierPath()
        cup.move(to: NSPoint(x: 3.2, y: 4))
        cup.line(to: NSPoint(x: 12.8, y: 4))
        cup.line(to: NSPoint(x: 12.1, y: 13.2))
        cup.curve(to: NSPoint(x: 9.6, y: 15.5), quadControl: NSPoint(x: 11.9, y: 15.5))
        cup.line(to: NSPoint(x: 6.4, y: 15.5))
        cup.curve(to: NSPoint(x: 3.9, y: 13.2), quadControl: NSPoint(x: 4.1, y: 15.5))
        cup.close()

        let handle = NSBezierPath()
        handle.move(to: NSPoint(x: 12.7, y: 6.4))
        handle.curve(to: NSPoint(x: 15.5, y: 9.1), quadControl: NSPoint(x: 15.7, y: 6.4))
        handle.curve(to: NSPoint(x: 12.3, y: 11.6), quadControl: NSPoint(x: 15.3, y: 11.6))

        for path in [cup, handle] {
            path.lineWidth = 1.4
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            path.stroke()
        }

        guard level > 0 else { return }
        NSGraphicsContext.saveGraphicsState()
        let tea = NSBezierPath()
        tea.move(to: NSPoint(x: 4.7, y: 6.2))
        tea.line(to: NSPoint(x: 11.3, y: 6.2))
        tea.line(to: NSPoint(x: 10.8, y: 13))
        tea.curve(to: NSPoint(x: 9.5, y: 14.1), quadControl: NSPoint(x: 10.7, y: 14.1))
        tea.line(to: NSPoint(x: 6.5, y: 14.1))
        tea.curve(to: NSPoint(x: 5.2, y: 13), quadControl: NSPoint(x: 5.3, y: 14.1))
        tea.close()
        tea.addClip()

        let surface = 14.1 - (14.1 - 6.2) * level
        NSRect(x: 0, y: surface, width: cupSize, height: cupSize - surface).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

extension NSBezierPath {
    fileprivate nonisolated func curve(to end: NSPoint, quadControl control: NSPoint) {
        let start = currentPoint
        curve(
            to: end,
            controlPoint1: NSPoint(x: start.x + 2 / 3 * (control.x - start.x), y: start.y + 2 / 3 * (control.y - start.y)),
            controlPoint2: NSPoint(x: end.x + 2 / 3 * (control.x - end.x), y: end.y + 2 / 3 * (control.y - end.y))
        )
    }
}
