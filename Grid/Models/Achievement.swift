import Foundation

/// A session-count milestone. Earned trophies are stamped onto the back of the
/// 3D Pro pass and shown in Stats. Thresholds: 1, 5, 10, 15, 20, 30, 50.
struct Achievement: Identifiable, Hashable {
    /// Finished sessions required to earn it.
    let sessions: Int
    let name: String
    /// SF Symbol used as the stamp glyph.
    let icon: String
    var id: Int { sessions }

    func isEarned(finishedSessions: Int) -> Bool { finishedSessions >= sessions }
}

enum Achievements {
    static let all: [Achievement] = [
        Achievement(sessions: 1,  name: "First Lap",     icon: "flag.checkered"),
        Achievement(sessions: 5,  name: "Points Finish", icon: "star.fill"),
        Achievement(sessions: 10, name: "Podium",        icon: "trophy.fill"),
        Achievement(sessions: 15, name: "Race Winner",   icon: "medal.fill"),
        Achievement(sessions: 20, name: "Champion",      icon: "crown.fill"),
        Achievement(sessions: 30, name: "Veteran",       icon: "shield.lefthalf.filled"),
        Achievement(sessions: 50, name: "Legend",        icon: "bolt.fill"),
    ]

    static func earned(finishedSessions: Int) -> [Achievement] {
        all.filter { $0.isEarned(finishedSessions: finishedSessions) }
    }

    static func earnedCount(finishedSessions: Int) -> Int {
        all.filter { $0.isEarned(finishedSessions: finishedSessions) }.count
    }

    /// The next trophy still to unlock, if any.
    static func next(finishedSessions: Int) -> Achievement? {
        all.first { !$0.isEarned(finishedSessions: finishedSessions) }
    }
}
