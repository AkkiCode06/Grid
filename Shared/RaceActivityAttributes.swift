import Foundation
#if canImport(ActivityKit)
import ActivityKit

struct RaceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentLap: Int
        var totalLaps: Int
        var startDate: Date
        var endDate: Date
    }

    var circuitName: String
    var teamName: String
    var sessionNumber: Int
}
#endif
