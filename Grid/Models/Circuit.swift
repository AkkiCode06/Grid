import Foundation

struct Circuit: Identifiable, Codable, Hashable {
    let id: String
    /// Display name is data-driven so renaming for trademark safety is trivial.
    let name: String
    let country: String
    let flag: String
    /// nil means the user picks the duration (custom circuit).
    let durationMinutes: Int?
    let lapSeconds: Double
    let isFree: Bool
    /// Hex colors for the placeholder backdrop gradient until real art lands.
    let skyColors: [String]

    var isCustom: Bool { durationMinutes == nil }

    func duration(customMinutes: Int) -> TimeInterval {
        TimeInterval((durationMinutes ?? customMinutes) * 60)
    }

    func totalLaps(customMinutes: Int) -> Int {
        max(1, Int((duration(customMinutes: customMinutes) / lapSeconds).rounded(.up)))
    }
}

enum CircuitLibrary {
    static let all: [Circuit] = [
        Circuit(
            id: "monteCarlo",
            name: "Monte Carlo Street Circuit",
            country: "Monaco",
            flag: "🇲🇨",
            durationMinutes: 25,
            lapSeconds: 75,
            isFree: true,
            skyColors: ["FFB347", "FF6961", "2B2D42"]
        ),
        Circuit(
            id: "marina",
            name: "Twilight Marina Circuit",
            country: "Abu Dhabi",
            flag: "🇦🇪",
            durationMinutes: 45,
            lapSeconds: 95,
            isFree: false,
            skyColors: ["1B0C42", "5C2A9D", "F72585"]
        ),
        Circuit(
            id: "midlands",
            name: "Midlands GP Circuit",
            country: "Great Britain",
            flag: "🇬🇧",
            durationMinutes: 60,
            lapSeconds: 90,
            isFree: true,
            skyColors: ["A7C7E7", "6096BA", "274C77"]
        ),
        Circuit(
            id: "hachi",
            name: "Hachi Ring",
            country: "Japan",
            flag: "🇯🇵",
            durationMinutes: 90,
            lapSeconds: 95,
            isFree: false,
            skyColors: ["FAD4D8", "EF798A", "3F2B47"]
        ),
        Circuit(
            id: "ardennes",
            name: "Ardennes GP",
            country: "Belgium",
            flag: "🇧🇪",
            durationMinutes: 120,
            lapSeconds: 105,
            isFree: false,
            skyColors: ["96B8A5", "5E8C61", "2C423F"]
        ),
        Circuit(
            id: "royalPark",
            name: "Royal Park Circuit",
            country: "Italy",
            flag: "🇮🇹",
            durationMinutes: 30,
            lapSeconds: 82,
            isFree: false,
            skyColors: ["8FB9E8", "4A90D9", "1B3A5C"]
        ),
        Circuit(
            id: "bayCity",
            name: "Bay City Night Circuit",
            country: "Singapore",
            flag: "🇸🇬",
            durationMinutes: 120,
            lapSeconds: 100,
            isFree: false,
            skyColors: ["0B1026", "1B2A6B", "F72585"]
        ),
        Circuit(
            id: "loneStar",
            name: "Lone Star Circuit",
            country: "United States",
            flag: "🇺🇸",
            durationMinutes: 60,
            lapSeconds: 96,
            isFree: false,
            skyColors: ["FFB86B", "E8642F", "2B2036"]
        ),
        Circuit(
            id: "serraVerde",
            name: "Serra Verde Circuit",
            country: "Brazil",
            flag: "🇧🇷",
            durationMinutes: 45,
            lapSeconds: 72,
            isFree: false,
            skyColors: ["9DBF9E", "5E8C61", "2C3B2E"]
        ),
        Circuit(
            id: "caspian",
            name: "Caspian Street Circuit",
            country: "Azerbaijan",
            flag: "🇦🇿",
            durationMinutes: 90,
            lapSeconds: 104,
            isFree: true,
            skyColors: ["E8C39E", "C77D4A", "2E2233"]
        ),
        Circuit(
            id: "dunePark",
            name: "Dune Park Circuit",
            country: "Netherlands",
            flag: "🇳🇱",
            durationMinutes: 25,
            lapSeconds: 72,
            isFree: true,
            skyColors: ["BCD4E6", "6A9BC3", "2A3F55"]
        ),
        Circuit(
            id: "alpine",
            name: "Alpine Ring",
            country: "Austria",
            flag: "🇦🇹",
            durationMinutes: 40,
            lapSeconds: 67,
            isFree: true,
            skyColors: ["A7D3A7", "5E9C6B", "243B2E"]
        ),
        Circuit(
            id: "custom",
            name: "Private Test Track",
            country: "Anywhere",
            flag: "🏁",
            durationMinutes: nil,
            lapSeconds: 90,
            isFree: false,
            skyColors: ["444455", "222233", "111119"]
        ),
    ]

    static func circuit(id: String) -> Circuit? {
        all.first { $0.id == id }
    }
}
