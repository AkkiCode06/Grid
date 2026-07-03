import SwiftUI

enum Theme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let card = Color(red: 0.10, green: 0.10, blue: 0.14)
    static let cardHighlight = Color(red: 0.16, green: 0.16, blue: 0.21)
    static let raceRed = Color(red: 0.90, green: 0.10, blue: 0.15)
    static let gold = Color(red: 0.85, green: 0.70, blue: 0.30)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)
}

extension Font {
    /// Monospaced "pit wall telemetry" style used for timers and counters.
    static func telemetry(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
