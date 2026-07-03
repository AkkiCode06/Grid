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
}

enum TeamLibrary {
    static let all: [Team] = [
        Team(id: "papaya", name: "Papaya Racing", tagline: "Fearlessly forward",
             accentHex: "FF8700", inkHex: "17171A", foilHex: "E8E9EC"),
        Team(id: "rosso", name: "Rosso Corse", tagline: "Avanti tutta",
             accentHex: "E10A17", inkHex: "17171A", foilHex: "FFD34D"),
        Team(id: "argento", name: "Argento GP", tagline: "Precision in silver",
             accentHex: "D8D8DC", inkHex: "10182B", foilHex: "0A7E8C"),
        Team(id: "midnight", name: "Midnight Blu", tagline: "Chase the night",
             accentHex: "1B1E3C", inkHex: "F5F5F7", foilHex: "E10A17"),
        Team(id: "verdant", name: "Verdant Racing", tagline: "Green light only",
             accentHex: "1E5A46", inkHex: "F5F5F7", foilHex: "D9B45B"),
        Team(id: "ivory", name: "Ivory Privateers", tagline: "Vintage speed",
             accentHex: "F2EDE4", inkHex: "17171A", foilHex: "D9B45B"),
    ]

    static func team(id: String) -> Team? {
        all.first { $0.id == id }
    }

    static func team(named name: String) -> Team? {
        all.first { $0.name == name }
    }
}
