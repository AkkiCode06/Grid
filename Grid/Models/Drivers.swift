import Foundation

/// Fictional rivals that circulate on the tracker with the user. Codes are
/// invented three-letter tags (no real F1 drivers). Each rival laps at a
/// slightly different pace so the field spreads out naturally over a session.
struct Rival: Identifiable, Hashable {
    let code: String
    let name: String
    let colorHex: String
    /// Base multiplier on the circuit's lap time — randomized per session
    /// within ±spread around this value.
    let basePaceFactor: Double
    /// How much the pace varies session-to-session (e.g. 0.04 = ±4%).
    let spread: Double

    var id: String { code }

    /// Deterministic but unique pace factor for a given session seed.
    func paceFactor(seed: Int) -> Double {
        // Simple hash per rival per session for deterministic randomness
        var state = UInt64(bitPattern: Int64(seed &* 31 &+ code.hashValue))
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let normalized = Double(state >> 33) / Double(UInt32.max) // 0...1
        return basePaceFactor + spread * (normalized * 2 - 1)
    }

    /// Fraction around the lap at a given elapsed time. All drivers start
    /// from the starting line (fraction 0).
    func lapFraction(elapsed: TimeInterval, lapSeconds: Double, sessionSeed: Int) -> Double {
        let lap = lapSeconds * paceFactor(seed: sessionSeed)
        let f = elapsed / lap
        return f - f.rounded(.down)
    }
}

enum RivalGrid {
    static let all: [Rival] = [
        Rival(code: "KAT", name: "Katsu", colorHex: "E10A17", basePaceFactor: 0.972, spread: 0.04),
        Rival(code: "MOR", name: "Moreau", colorHex: "00C2CC", basePaceFactor: 0.988, spread: 0.035),
        Rival(code: "RIV", name: "Rivera", colorHex: "4C6FFF", basePaceFactor: 1.004, spread: 0.04),
        Rival(code: "OKA", name: "Okafor", colorHex: "2ECC71", basePaceFactor: 1.018, spread: 0.038),
        Rival(code: "SOR", name: "Sørensen", colorHex: "F5C542", basePaceFactor: 1.031, spread: 0.045),
        Rival(code: "BLZ", name: "Blažek", colorHex: "B96BFF", basePaceFactor: 0.996, spread: 0.04),
    ]
}
