import SwiftUI
import UIKit

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
    /// App-wide "pit wall" style, now mapped onto the Gilroy family so the
    /// whole app picks it up without touching every call site.
    static func telemetry(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        let gilroy: GilroyWeight
        if weight == .black {
            gilroy = .black
        } else if weight == .heavy {
            gilroy = .heavy
        } else if weight == .bold {
            gilroy = .bold
        } else if weight == .medium {
            gilroy = .medium
        } else if weight == .light || weight == .thin || weight == .ultraLight {
            gilroy = .light
        } else if weight == .regular {
            gilroy = .regular
        } else {
            gilroy = .semiBold
        }
        return .gilroy(size, gilroy)
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

    func hexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "%02X%02X%02X",
            Int(round(red * 255)), Int(round(green * 255)), Int(round(blue * 255))
        )
    }
}
