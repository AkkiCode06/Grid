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

    /// Pit-wall/paddock view backdrop for the racing screen (supplied later).
    var paddockBackdropAsset: String { "\(id)_paddock_backdrop" }

    /// Bundled clip names (without extension) for flyby videos (supplied later).
    var flybyClips: [String] { (1...5).map { "\(id)_paddock_flyby\($0)" } }

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
