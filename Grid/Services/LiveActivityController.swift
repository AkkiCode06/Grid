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
            teamName: pass.team.name,
            teamColorHex: pass.team.accentHex,
            sessionNumber: pass.sessionNumber
        )
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let state = RaceActivityAttributes.ContentState(
            currentLap: 1,
            totalLaps: pass.totalLaps,
            startDate: startDate,
            endDate: endDate,
            flagRaw: nil,
            awayDeadline: nil
        )
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: endDate)
        )
    }

    func updateLap(_ lap: Int, pass: PassDetails, startDate: Date) async {
        guard let activity else { return }
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        var state = activity.content.state
        state.currentLap = lap
        state.totalLaps = pass.totalLaps
        state.startDate = startDate
        state.endDate = endDate
        await activity.update(.init(state: state, staleDate: endDate))
    }

    /// The user left the app: start the grace countdown. The widget counts
    /// down to `deadline`, then renders the yellow flag once the activity goes
    /// stale at that date (the app is suspended and can't push again). Fires an
    /// alert so the phone buzzes the moment they leave.
    func startAway(deadline: Date) async {
        guard let activity else { return }
        var state = activity.content.state
        state.awayDeadline = deadline
        state.flagRaw = "yellow"
        let alert = AlertConfiguration(
            title: "🟡 Race control",
            body: "Get back to Grid before you're yellow flagged.",
            sound: .default
        )
        await activity.update(
            .init(state: state, staleDate: deadline),
            alertConfiguration: alert
        )
    }

    /// The user came back: clear the away state.
    func clearAway() async {
        guard let activity else { return }
        var state = activity.content.state
        state.awayDeadline = nil
        state.flagRaw = nil
        await activity.update(.init(state: state, staleDate: state.endDate))
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
