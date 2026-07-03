import Foundation

enum SharedConstants {
    static let appGroupID = "group.Akki.Grid"
    static let managedSettingsStoreName = "gridRaceShield"
    static let deviceActivityName = "gridRaceSession"
}

/// Snapshot of the active race session, persisted to the App Group so the
/// DeviceActivity extension can act on it and the app can restore state
/// after being killed mid-session.
struct ActiveSessionSnapshot: Codable {
    var driverName: String
    var circuitID: String
    var circuitName: String
    var seatName: String
    var sessionNumber: Int
    var startDate: Date
    var durationSeconds: TimeInterval
    var lapSeconds: TimeInterval

    var endDate: Date { startDate.addingTimeInterval(durationSeconds) }

    var totalLaps: Int {
        max(1, Int((durationSeconds / lapSeconds).rounded(.up)))
    }

    func currentLap(at date: Date = .now) -> Int {
        let elapsed = max(0, date.timeIntervalSince(startDate))
        return min(totalLaps, Int(elapsed / lapSeconds) + 1)
    }
}

enum SharedStore {
    static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedConstants.appGroupID) ?? .standard
    }

    private static let activeSessionKey = "activeSessionSnapshot"
    private static let sessionCounterKey = "sessionCounter"
    private static let activitySelectionKey = "familyActivitySelection"

    static func saveActiveSession(_ snapshot: ActiveSessionSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: activeSessionKey)
        }
    }

    static func loadActiveSession() -> ActiveSessionSnapshot? {
        guard let data = defaults.data(forKey: activeSessionKey) else { return nil }
        return try? JSONDecoder().decode(ActiveSessionSnapshot.self, from: data)
    }

    static func clearActiveSession() {
        defaults.removeObject(forKey: activeSessionKey)
    }

    /// The next session number to print on a pass (1-based, incremented on commit).
    static var nextSessionNumber: Int {
        max(1, defaults.integer(forKey: sessionCounterKey) + 1)
    }

    static func consumeSessionNumber() {
        defaults.set(nextSessionNumber, forKey: sessionCounterKey)
    }

    static func saveActivitySelection(_ data: Data) {
        defaults.set(data, forKey: activitySelectionKey)
    }

    static func loadActivitySelection() -> Data? {
        defaults.data(forKey: activitySelectionKey)
    }
}
