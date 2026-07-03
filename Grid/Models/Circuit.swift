import Foundation

struct Seat: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    /// Image asset name for the grandstand backdrop (supplied later).
    let backdropAsset: String
    /// Bundled clip names (without extension) for flyby videos (supplied later).
    let flybyClips: [String]
}

struct Circuit: Identifiable, Codable, Hashable {
    let id: String
    /// Display name is data-driven so renaming for trademark safety is trivial.
    let name: String
    let country: String
    let flag: String
    /// nil means the user picks the duration (custom circuit).
    let durationMinutes: Int?
    let lapSeconds: Double
    let seats: [Seat]
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
            seats: seats(for: "monteCarlo",
                         ["Casino Straight", "Harbour Hairpin", "Piscine Chicane"]),
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
            seats: seats(for: "marina",
                         ["Grandstand Straight", "Hotel Hairpin", "Marina Chicane"]),
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
            seats: seats(for: "midlands",
                         ["Main Straight", "Loop Hairpin", "Farm Chicane"]),
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
            seats: seats(for: "hachi",
                         ["Grand Straight", "Crossover Hairpin", "Esses Chicane"]),
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
            seats: seats(for: "ardennes",
                         ["Forest Straight", "Valley Hairpin", "Forest Chicane"]),
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
            seats: seats(for: "custom",
                         ["Main Straight", "Hairpin", "Chicane"]),
            isFree: false,
            skyColors: ["444455", "222233", "111119"]
        ),
    ]

    static func circuit(id: String) -> Circuit? {
        all.first { $0.id == id }
    }

    private static func seats(for circuitID: String, _ names: [String]) -> [Seat] {
        zip(["mainStraight", "hairpin", "chicane"], names).map { seatID, name in
            Seat(
                id: seatID,
                name: name,
                backdropAsset: "\(circuitID)_\(seatID)_backdrop",
                flybyClips: (1...3).map { "\(circuitID)_\(seatID)_flyby\($0)" }
            )
        }
    }
}
