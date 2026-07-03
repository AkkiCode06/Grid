import SwiftUI

/// Stylised, legally-safe track outlines defined as closed polylines in unit
/// space, smoothed with Catmull-Rom at render time. These are evocative of
/// each circuit's character without tracing any official layout.
enum TrackOutlines {
    static func points(for circuitID: String) -> [CGPoint] {
        switch circuitID {
        case "monteCarlo":
            return unit([
                (0.15, 0.75), (0.10, 0.45), (0.20, 0.25), (0.40, 0.15),
                (0.62, 0.20), (0.72, 0.10), (0.88, 0.15), (0.90, 0.35),
                (0.75, 0.45), (0.85, 0.60), (0.70, 0.80), (0.45, 0.85),
                (0.30, 0.90),
            ])
        case "marina":
            return unit([
                (0.10, 0.80), (0.08, 0.50), (0.20, 0.30), (0.45, 0.22),
                (0.55, 0.35), (0.70, 0.20), (0.90, 0.25), (0.92, 0.50),
                (0.80, 0.62), (0.88, 0.78), (0.60, 0.88), (0.30, 0.88),
            ])
        case "midlands":
            return unit([
                (0.12, 0.60), (0.15, 0.30), (0.35, 0.15), (0.60, 0.20),
                (0.80, 0.12), (0.90, 0.30), (0.78, 0.45), (0.88, 0.65),
                (0.70, 0.82), (0.45, 0.75), (0.28, 0.85),
            ])
        case "hachi":
            return unit([
                (0.20, 0.70), (0.12, 0.45), (0.25, 0.25), (0.45, 0.30),
                (0.60, 0.50), (0.75, 0.30), (0.90, 0.40), (0.85, 0.65),
                (0.65, 0.70), (0.50, 0.55), (0.35, 0.75),
            ])
        case "ardennes":
            return unit([
                (0.15, 0.85), (0.10, 0.60), (0.25, 0.35), (0.45, 0.15),
                (0.60, 0.10), (0.70, 0.25), (0.60, 0.45), (0.75, 0.60),
                (0.90, 0.70), (0.70, 0.88), (0.40, 0.90),
            ])
        default:
            return unit([
                (0.15, 0.50), (0.25, 0.25), (0.50, 0.18), (0.75, 0.25),
                (0.85, 0.50), (0.75, 0.75), (0.50, 0.82), (0.25, 0.75),
            ])
        }
    }

    private static func unit(_ tuples: [(Double, Double)]) -> [CGPoint] {
        tuples.map { CGPoint(x: $0.0, y: $0.1) }
    }
}

/// Draws a circuit's outline scaled into `rect`. Use `.trim(from:to:)` on it
/// for the lap-progress fill.
struct TrackOutlineShape: Shape {
    let circuitID: String

    func path(in rect: CGRect) -> Path {
        let points = TrackOutlines.points(for: circuitID).map { point in
            CGPoint(x: rect.minX + point.x * rect.width,
                    y: rect.minY + point.y * rect.height)
        }
        return Path.catmullRomClosed(through: points)
    }
}

extension Path {
    /// Closed Catmull-Rom spline through the given points, converted to
    /// cubic Bezier segments.
    static func catmullRomClosed(through points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 2 else {
            path.addLines(points)
            path.closeSubpath()
            return path
        }
        let n = points.count
        path.move(to: points[0])
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n]
            let p1 = points[i]
            let p2 = points[(i + 1) % n]
            let p3 = points[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6,
                             y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6,
                             y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }
}
