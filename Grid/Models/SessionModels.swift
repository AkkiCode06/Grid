import Foundation

/// Everything printed on a paddock pass, fixed at issue time.
struct PassDetails: Hashable, Codable {
    var driverName: String
    var circuit: Circuit
    var seat: Seat
    var issuedAt: Date
    var sessionNumber: Int
    var durationSeconds: TimeInterval

    var totalLaps: Int {
        max(1, Int((durationSeconds / circuit.lapSeconds).rounded(.up)))
    }

    var sessionLabel: String {
        String(format: "SESSION %03d", sessionNumber)
    }
}

enum RaceResult: String, Codable {
    case finished = "FINISHED"
    case dnf = "DNF"
}

/// The session state machine:
/// idle → passIssued → lightsSequence → racing → ended(finished | dnf) → idle
enum SessionPhase: Equatable {
    case idle
    case passIssued(PassDetails)
    case lightsSequence(PassDetails)
    case racing(PassDetails, startDate: Date)
    case ended(PassDetails, startDate: Date, result: RaceResult)
}
