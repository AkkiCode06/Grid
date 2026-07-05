import Foundation

/// Fictional racing teams — legally safe, colour-driven. Picking a team
/// applies its livery to the paddock pass and stamps the team name on it.
struct Team: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let accentHex: String   // livery primary → pass card colour
    let inkHex: String      // print colour on that livery
    let foilHex: String     // script flourish colour
    let threeLetterCode: String
    let carNumber: Int
    let assetName: String
    /// Premium livery — only selectable with Pro.
    var isPro: Bool = false
}

enum TeamLibrary {
    static let all: [Team] = [
        Team(id: "papaya", name: "Papaya Racing", tagline: "Fearlessly forward",
             accentHex: "FF8700", inkHex: "17171A", foilHex: "E8E9EC",
             threeLetterCode: "PAP", carNumber: 4, assetName: "team_papaya"),
        Team(id: "rosso", name: "Rosso Corse", tagline: "Avanti tutta",
             accentHex: "E10A17", inkHex: "17171A", foilHex: "FFD34D",
             threeLetterCode: "ROS", carNumber: 16, assetName: "team_rosso"),
        Team(id: "argento", name: "Argento GP", tagline: "Precision in silver",
             accentHex: "D8D8DC", inkHex: "10182B", foilHex: "0A7E8C",
             threeLetterCode: "ARG", carNumber: 63, assetName: "team_argento"),
        Team(id: "midnight", name: "Midnight Blu", tagline: "Chase the night",
             accentHex: "1B1E3C", inkHex: "F5F5F7", foilHex: "E10A17",
             threeLetterCode: "MID", carNumber: 23, assetName: "team_midnight"),
        Team(id: "verdant", name: "Verdant Racing", tagline: "Green light only",
             accentHex: "1E5A46", inkHex: "F5F5F7", foilHex: "D9B45B",
             threeLetterCode: "VER", carNumber: 14, assetName: "team_verdant"),
        Team(id: "ivory", name: "Ivory Privateers", tagline: "Vintage speed",
             accentHex: "F2EDE4", inkHex: "17171A", foilHex: "D9B45B",
             threeLetterCode: "IVO", carNumber: 77, assetName: "team_ivory"),

        // MARK: Premium liveries (Pro)
        Team(id: "cobalt", name: "Cobalt Dynamics", tagline: "Voltage unleashed",
             accentHex: "1F6FEB", inkHex: "F5F5F7", foilHex: "36E2FF",
             threeLetterCode: "COB", carNumber: 9, assetName: "team_cobalt", isPro: true),
        Team(id: "solaris", name: "Solaris Works", tagline: "Chase the sun",
             accentHex: "FFC300", inkHex: "17171A", foilHex: "17171A",
             threeLetterCode: "SOL", carNumber: 27, assetName: "team_solaris", isPro: true),
        Team(id: "onyx", name: "Onyx Prestige", tagline: "Black gold",
             accentHex: "0E0E10", inkHex: "F5F5F7", foilHex: "D9B45B",
             threeLetterCode: "ONX", carNumber: 1, assetName: "team_onyx", isPro: true),
        Team(id: "magenta", name: "Magenta Volt", tagline: "Electric edge",
             accentHex: "E5006E", inkHex: "F5F5F7", foilHex: "FF9EC7",
             threeLetterCode: "MGV", carNumber: 88, assetName: "team_magenta", isPro: true),
        Team(id: "crimson", name: "Crimson Apex", tagline: "Point of no return",
             accentHex: "8B0000", inkHex: "F5F5F7", foilHex: "FF5A3C",
             threeLetterCode: "CRA", carNumber: 51, assetName: "team_crimson", isPro: true),
    ]

    /// Teams available on the free tier.
    static var free: [Team] { all.filter { !$0.isPro } }

    static func team(id: String) -> Team? {
        all.first { $0.id == id }
    }

    static func team(named name: String) -> Team? {
        all.first { $0.name == name }
    }
}
