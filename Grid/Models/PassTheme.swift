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

/// An individually-selectable region of the pass in Pass Studio.
enum PassPart: String, CaseIterable, Identifiable {
    case card          // card colour + texture
    case bigPrint      // role text ("VIP")
    case script        // flourish ("Guest")
    case year
    case detailsStrip  // ink colour of the info strip
    case track         // track outline colour
    case event         // event line text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card: return "Card"
        case .bigPrint: return "Big Print"
        case .script: return "Flourish"
        case .year: return "Year"
        case .detailsStrip: return "Info Strip"
        case .track: return "Track"
        case .event: return "Event Line"
        }
    }

    var editsText: Bool {
        switch self {
        case .bigPrint, .script, .year, .event: return true
        case .card, .detailsStrip, .track: return false
        }
    }

    var editsFontAndSize: Bool {
        self == .bigPrint || self == .script
    }
}

/// Card surface finish.
enum PassTexture: String, Codable, CaseIterable {
    case matte
    case gloss
    case carbon
    case holographic   // pro-only, radiant sheen

    var label: String {
        switch self {
        case .matte: return "Matte"
        case .gloss: return "Gloss"
        case .carbon: return "Carbon"
        case .holographic: return "Holo"
        }
    }
}

/// A named Gilroy weight the user can assign to a text element.
enum PassFont: String, Codable, CaseIterable {
    case heavy, black, extraBold, bold, semiBold, medium, light, script

    var label: String {
        switch self {
        case .script: return "Script"
        default: return rawValue.capitalized
        }
    }

    /// Returns a SwiftUI font at the given size. `.script` maps to Snell.
    func font(_ size: CGFloat) -> Font {
        switch self {
        case .heavy: return .gilroy(size, .heavy)
        case .black: return .gilroy(size, .black)
        case .extraBold: return .gilroy(size, .extraBold)
        case .bold: return .gilroy(size, .bold)
        case .semiBold: return .gilroy(size, .semiBold)
        case .medium: return .gilroy(size, .medium)
        case .light: return .gilroy(size, .light)
        case .script: return .custom("SnellRoundhand-Bold", size: size)
        }
    }
}

/// Everything the user can customise about their paddock pass. The pass
/// stays on-theme (lanyard card, stripe bands, block print) but wording,
/// colours, fonts, sizes, and texture are all theirs.
struct PassTheme: Codable, Equatable {
    var accentHex: String = "FF8700"   // card colour (papaya default)
    var inkHex: String = "17171A"      // print / details colour
    var foilHex: String = "E8E9EC"     // script flourish colour
    var trackHex: String = "17171A"    // track outline colour
    var roleText: String = "VIP"
    var scriptText: String = "Guest"
    var yearText: String = PassTheme.currentYear
    var eventText: String = "GRID FOCUS CHAMPIONSHIP"

    // Per-element typography (multipliers on the card's base sizing).
    var roleFont: PassFont = .black
    var roleScale: Double = 1.0
    var scriptFont: PassFont = .script
    var scriptScale: Double = 1.0

    var texture: PassTexture = .matte

    var dateStyle: PassDateStyle = .dateAndTime
    var showBarcode: Bool = true
    var showTrackOutline: Bool = true
    var showSessionNumber: Bool = true

    static let currentYear = String(Calendar.current.component(.year, from: .now))

    var accent: Color { Color(hex: accentHex) }
    var ink: Color { Color(hex: inkHex) }
    var foil: Color { Color(hex: foilHex) }
    var track: Color { Color(hex: trackHex) }
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

    /// Picking a team applies its livery to the pass. Everything stays
    /// individually tweakable in Pass Studio afterwards.
    func applyTeam(_ team: Team) {
        theme.accentHex = team.accentHex
        theme.inkHex = team.inkHex
        theme.foilHex = team.foilHex
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
