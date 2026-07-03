import Foundation
import SwiftData

/// One entry in the Race Log — a stamped pass, kept forever.
@Model
final class RaceRecord {
    var driverName: String
    var circuitID: String
    var circuitName: String
    var seatName: String
    var sessionNumber: Int
    var startDate: Date
    var plannedSeconds: TimeInterval
    var completedSeconds: TimeInterval
    var lapSeconds: Double
    var resultRaw: String

    init(driverName: String,
         circuitID: String,
         circuitName: String,
         seatName: String,
         sessionNumber: Int,
         startDate: Date,
         plannedSeconds: TimeInterval,
         completedSeconds: TimeInterval,
         lapSeconds: Double,
         result: RaceResult) {
        self.driverName = driverName
        self.circuitID = circuitID
        self.circuitName = circuitName
        self.seatName = seatName
        self.sessionNumber = sessionNumber
        self.startDate = startDate
        self.plannedSeconds = plannedSeconds
        self.completedSeconds = completedSeconds
        self.lapSeconds = lapSeconds
        self.resultRaw = result.rawValue
    }

    var result: RaceResult { RaceResult(rawValue: resultRaw) ?? .dnf }

    var totalLaps: Int {
        max(1, Int((plannedSeconds / lapSeconds).rounded(.up)))
    }

    var completedLaps: Int {
        min(totalLaps, Int(completedSeconds / lapSeconds))
    }
}
