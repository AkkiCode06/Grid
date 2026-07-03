import Foundation

/// Deterministic seeded RNG (splitmix64) so a session always replays the
/// same race: same pace, same pit stops, same classification.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Per-session race simulation for the rival field: randomized pace, one
/// five-minute pit stop each (never inside the final 15 minutes), and the
/// final classification decided by weighted luck — the user holds one
/// ticket plus one bonus ticket for every session they've fully finished.
struct RaceSimulation {
    struct RivalState: Identifiable {
        let rival: Rival
        let paceFactor: Double
        /// When this rival dives into the pits; nil if the race is too
        /// short to fit a stop outside the protected final 15 minutes.
        let pitStart: TimeInterval?

        static let pitDuration: TimeInterval = 5 * 60

        var id: String { rival.code }

        func isInPit(elapsed: TimeInterval) -> Bool {
            guard let pitStart else { return false }
            return elapsed >= pitStart && elapsed < pitStart + Self.pitDuration
        }

        /// Time actually spent driving — the car freezes while in the pit.
        private func drivingTime(elapsed: TimeInterval) -> TimeInterval {
            guard let pitStart, elapsed > pitStart else { return elapsed }
            return pitStart + max(0, elapsed - pitStart - Self.pitDuration)
        }

        func lapFraction(elapsed: TimeInterval, lapSeconds: Double) -> Double {
            let f = drivingTime(elapsed: elapsed) / (lapSeconds * paceFactor)
            return f - f.rounded(.down)
        }
    }

    let rivals: [RivalState]
    private let seed: Int
    private let lapSeconds: Double

    init(seed: Int, duration: TimeInterval, lapSeconds: Double) {
        self.seed = seed
        self.lapSeconds = lapSeconds
        var rng = SeededRNG(seed: seed)
        // Pit window: from 20% into the race up to 15 min + pit length
        // before the flag. Short sessions get no stops.
        let windowStart = duration * 0.2
        let windowEnd = duration - 15 * 60 - RivalState.pitDuration
        rivals = RivalGrid.all.map { rival in
            let jitter = Double.random(in: -1...1, using: &rng)
            let pace = rival.basePaceFactor + rival.spread * jitter
            let pit: TimeInterval? = windowEnd > windowStart
                ? Double.random(in: windowStart...windowEnd, using: &rng)
                : nil
            return RivalState(rival: rival, paceFactor: pace, pitStart: pit)
        }
    }

    /// Final classification, "YOU" included. Every rival holds one ticket;
    /// the user holds 1 + `userBonus` (earned +1 per finished session), so
    /// early races put you at the back and finishing streaks pull you up
    /// the order.
    func finishingOrder(userBonus: Int) -> [String] {
        var rng = SeededRNG(seed: seed &* 7919 &+ userBonus &+ 1)
        var entries: [(code: String, weight: Double)] =
            rivals.map { ($0.rival.code, 1.0) } + [("YOU", 1.0 + Double(max(0, userBonus)))]
        var order: [String] = []
        while !entries.isEmpty {
            let total = entries.reduce(0.0) { $0 + $1.weight }
            var pick = Double.random(in: 0..<total, using: &rng)
            var chosen = entries.count - 1
            for (index, entry) in entries.enumerated() {
                pick -= entry.weight
                if pick < 0 {
                    chosen = index
                    break
                }
            }
            order.append(entries.remove(at: chosen).code)
        }
        return order
    }

    /// Fabricated best-lap times consistent with the classification —
    /// P1 fastest, believable gaps down the order.
    func bestLaps(for order: [String]) -> [String: TimeInterval] {
        var rng = SeededRNG(seed: seed &* 104729)
        var laps: [String: TimeInterval] = [:]
        var time = lapSeconds * Double.random(in: 0.955...0.97, using: &rng)
        for code in order {
            laps[code] = time
            time += Double.random(in: 0.12...0.85, using: &rng)
        }
        return laps
    }

    /// Marker colour for a classification code.
    static func colorHex(for code: String, userHex: String) -> String {
        if code == "YOU" { return userHex }
        return RivalGrid.all.first { $0.code == code }?.colorHex ?? "FFFFFF"
    }

    static func formatLap(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = seconds - Double(minutes * 60)
        return String(format: "%d:%06.3f", minutes, secs)
    }
}
