import Foundation
#if canImport(ActivityKit)
import ActivityKit

struct RaceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentLap: Int
        var totalLaps: Int
        var startDate: Date
        var endDate: Date
        /// Set the moment the user leaves the app: counting down to this is
        /// "warning" (about to be yellow flagged). Cleared on return.
        var awayDeadline: Date?
        /// Set alongside `awayDeadline` — counting down to this once
        /// yellow-flagged is "about to go red". Cleared on return.
        var redDeadline: Date?
    }

    var circuitName: String
    var teamName: String
    var teamColorHex: String
    var teamAssetName: String
    var sessionNumber: Int
}

/// Race-control severity while the user is away from the app. Derived purely
/// from comparing the current time against the two stored deadlines — no
/// app code needs to run in the background for this to be correct. It
/// self-heals on any redraw (screen wake, stale-date crossing, a tap), which
/// is the only mechanism iOS actually guarantees without a push server.
enum FlagSeverity {
    case none, warning, yellow, red

    /// `isStale` is a last-resort fallback only: if the activity somehow
    /// went stale (its `staleDate`, set to `awayDeadline`, has passed) but we
    /// can't tell from dates alone why, treat it as at least yellow.
    static func resolve(awayDeadline: Date?, redDeadline: Date?, isStale: Bool, now: Date = .now) -> FlagSeverity {
        guard let awayDeadline else { return .none }
        if let redDeadline, now >= redDeadline { return .red }
        if now >= awayDeadline { return .yellow }
        if isStale { return .yellow }
        return .warning
    }
}
#endif
