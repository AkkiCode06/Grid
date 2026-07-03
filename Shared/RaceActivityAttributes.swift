import Foundation
#if canImport(ActivityKit)
import ActivityKit

struct RaceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentLap: Int
        var totalLaps: Int
        var startDate: Date
        var endDate: Date
        /// "yellow" when the user has left the app mid-session; nil = green.
        var flagRaw: String?
        /// When set, the user has left the app: the widget counts down to this
        /// moment ("get back before you're flagged"), then — once the activity
        /// goes stale at this date — renders the yellow flag.
        var awayDeadline: Date?
    }

    var circuitName: String
    var teamName: String
    var teamColorHex: String
    var sessionNumber: Int
}
#endif
