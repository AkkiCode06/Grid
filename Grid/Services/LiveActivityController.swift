import Foundation
import ActivityKit

/// Starts, updates, and ends the race Live Activity. Updates happen only
/// while the app is foregrounded; the widget's timerInterval views keep the
/// countdown live in between without pushes.
final class LiveActivityController {
    private var activity: Activity<RaceActivityAttributes>?

    func start(pass: PassDetails, startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Reattach if a previous launch already started one (app was killed).
        if let existing = Activity<RaceActivityAttributes>.activities.first {
            activity = existing
            return
        }
        let attributes = RaceActivityAttributes(
            circuitName: pass.circuit.name,
            seatName: pass.seat.name,
            sessionNumber: pass.sessionNumber
        )
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let state = RaceActivityAttributes.ContentState(
            currentLap: 1,
            totalLaps: pass.totalLaps,
            startDate: startDate,
            endDate: endDate
        )
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: endDate)
        )
    }

    func updateLap(_ lap: Int, pass: PassDetails, startDate: Date) async {
        guard let activity else { return }
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let state = RaceActivityAttributes.ContentState(
            currentLap: lap,
            totalLaps: pass.totalLaps,
            startDate: startDate,
            endDate: endDate
        )
        await activity.update(.init(state: state, staleDate: endDate))
    }

    func end() async {
        guard let activity else { return }
        let state = activity.content.state
        await activity.end(
            .init(state: state, staleDate: nil),
            dismissalPolicy: .immediate
        )
        self.activity = nil
    }
}
