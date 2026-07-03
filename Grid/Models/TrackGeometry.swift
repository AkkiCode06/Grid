import SwiftUI

/// Arc-length parameterised position lookup along a circuit outline, fitted
/// into a rect with the same letterboxing as TrackOutlineShape — so car dots
/// computed here land exactly on the stroked outline.
struct TrackGeometry {
    private let points: [CGPoint]
    private let cumulative: [CGFloat]
    private let total: CGFloat

    init(circuitID: String, in rect: CGRect) {
        let outline = TrackOutlines.outline(for: circuitID)
        var width = rect.width
        var height = width / outline.aspect
        if height > rect.height {
            height = rect.height
            width = height * outline.aspect
        }
        let originX = rect.midX - width / 2
        let originY = rect.midY - height / 2
        var fitted = outline.points.map { point in
            CGPoint(x: originX + point.x * width, y: originY + point.y * height)
        }
        if let first = fitted.first {
            fitted.append(first)
        }
        var lengths: [CGFloat] = [0]
        for i in 1..<fitted.count {
            let d = hypot(fitted[i].x - fitted[i - 1].x, fitted[i].y - fitted[i - 1].y)
            lengths.append(lengths[i - 1] + d)
        }
        points = fitted
        cumulative = lengths
        total = lengths.last ?? 1
    }

    /// Point at `fraction` (0..<1) of the way around the lap.
    func point(at fraction: Double) -> CGPoint {
        guard points.count > 1, total > 0 else { return points.first ?? .zero }
        let wrapped = fraction - fraction.rounded(.down)
        let target = total * CGFloat(wrapped)
        var lo = 0
        var hi = cumulative.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if cumulative[mid] < target { lo = mid + 1 } else { hi = mid }
        }
        let index = max(1, lo)
        let segment = cumulative[index] - cumulative[index - 1]
        let t = segment > 0 ? (target - cumulative[index - 1]) / segment : 0
        let a = points[index - 1]
        let b = points[index]
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
