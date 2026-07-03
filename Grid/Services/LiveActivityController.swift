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
            sessionNumber: pass.sessionNumber
        )
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let state = RaceActivityAttributes.ContentState(
            currentLap: 1,
            totalLaps: pass.totalLaps,
            startDate: startDate,
            endDate: endDate,
            flagRaw: nil
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

    /// Waves (or clears) a flag on the Live Activity. Called as the app
    /// backgrounds, so it must be quick.
    ///
    /// When setting a yellow flag, pass a staleDate of `now + redDelay` so the
    /// widget can escalate to a red flag once the activity becomes stale (the
    /// app is suspended and can't push a second update).
    func setFlag(_ flagRaw: String?, staleDate: Date? = nil) async {
        guard let activity else { return }
        var state = activity.content.state
        state.flagRaw = flagRaw
        let resolvedStale = staleDate ?? state.endDate
        await activity.update(.init(state: state, staleDate: resolvedStale))
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
