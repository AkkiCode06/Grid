import Foundation
import SwiftData

/// One entry in the Race Log — a stamped pass, kept forever.
@Model
final class RaceRecord {
    var driverName: String
    var circuitID: String
    var circuitName: String
    @Attribute(originalName: "seatName") var teamName: String
    var sessionNumber: Int
    var startDate: Date
    var plannedSeconds: TimeInterval
    var completedSeconds: TimeInterval
    var lapSeconds: Double
    var resultRaw: String
    /// Times the user left the app mid-session (each backgrounding outside a
    /// pit stop). The GRID equivalent of "times you almost checked a
    /// blocked app" — the headline distraction metric on the Stats screen.
    var flagCount: Int = 0

    init(driverName: String,
         circuitID: String,
         circuitName: String,
         teamName: String,
         sessionNumber: Int,
         startDate: Date,
         plannedSeconds: TimeInterval,
         completedSeconds: TimeInterval,
         lapSeconds: Double,
         result: RaceResult,
         flagCount: Int = 0) {
        self.driverName = driverName
        self.circuitID = circuitID
        self.circuitName = circuitName
        self.teamName = teamName
        self.sessionNumber = sessionNumber
        self.startDate = startDate
        self.plannedSeconds = plannedSeconds
        self.completedSeconds = completedSeconds
        self.lapSeconds = lapSeconds
        self.resultRaw = result.rawValue
        self.flagCount = flagCount
    }

    var result: RaceResult { RaceResult(rawValue: resultRaw) ?? .dnf }

    var totalLaps: Int {
        max(1, Int((plannedSeconds / lapSeconds).rounded(.up)))
    }

    var completedLaps: Int {
        min(totalLaps, Int(completedSeconds / lapSeconds))
    }
}
