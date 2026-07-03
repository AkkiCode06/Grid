import SwiftUI

enum PassDateStyle: String, Codable, CaseIterable {
    case dateAndTime
    case dateOnly
    case timeOnly
    case hidden

    var label: String {
        switch self {
        case .dateAndTime: return "Date & time"
        case .dateOnly: return "Date only"
        case .timeOnly: return "Time only"
        case .hidden: return "Hidden"
        }
    }

    func text(for date: Date) -> String? {
        switch self {
        case .dateAndTime:
            return date.formatted(date: .abbreviated, time: .shortened)
        case .dateOnly:
            return date.formatted(date: .abbreviated, time: .omitted)
        case .timeOnly:
            return date.formatted(date: .omitted, time: .shortened)
        case .hidden:
            return nil
        }
    }
}

/// Everything the user can customise about their paddock pass. The pass
/// stays on-theme (lanyard card, stripe bands, block print) but wording,
/// colours, and which details are printed are all theirs.
struct PassTheme: Codable, Equatable {
    var accentHex: String = "FF8700"   // card colour (papaya default)
    var inkHex: String = "17171A"      // print colour
    var foilHex: String = "E8E9EC"     // script flourish colour
    var roleText: String = "VIP"
    var scriptText: String = "Guest"
    var yearText: String = PassTheme.currentYear
    var eventText: String = "GRID FOCUS CHAMPIONSHIP"
    var dateStyle: PassDateStyle = .dateAndTime
    var showBarcode: Bool = true
    var showTrackOutline: Bool = true
    var showSessionNumber: Bool = true

    static let currentYear = String(Calendar.current.component(.year, from: .now))

    var accent: Color { Color(hex: accentHex) }
    var ink: Color { Color(hex: inkHex) }
    var foil: Color { Color(hex: foilHex) }
}

@Observable
final class PassThemeStore {
    static let shared = PassThemeStore()

    var theme: PassTheme {
        didSet { save() }
    }

    private static let key = "passTheme"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(PassTheme.self, from: data) {
            theme = saved
        } else {
            theme = PassTheme()
        }
    }

    func reset() {
        theme = PassTheme()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(theme) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    // Preset swatches (name, hex). Custom colours are allowed everywhere.
    static let accentPresets: [(String, String)] = [
        ("Papaya", "FF8700"),
        ("Race Red", "E10A17"),
        ("Racing Green", "1E5A46"),
        ("Petrol", "0A7E8C"),
        ("Violet", "5D3FD3"),
        ("Ice", "D8D8DC"),
        ("Midnight", "1B1E28"),
    ]

    static let inkPresets: [(String, String)] = [
        ("Carbon", "17171A"),
        ("White", "F5F5F7"),
        ("Navy", "10182B"),
    ]

    static let foilPresets: [(String, String)] = [
        ("Silver", "E8E9EC"),
        ("Gold", "D9B45B"),
        ("Rose", "E8B4B8"),
        ("Carbon", "17171A"),
    ]
}
