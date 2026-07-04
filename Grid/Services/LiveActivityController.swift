import Foundation
import ActivityKit

/// Starts, updates, and ends the race Live Activity. Updates happen only
/// while the app is foregrounded; the widget's timerInterval views keep the
/// countdown live in between without pushes.
final class LiveActivityController {
    private var activity: Activity<RaceActivityAttributes>?

    func start(pass: PassDetails, startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Reattach only if a previous launch already started one FOR THIS
        // SESSION (app was killed mid-race). Anything else is a leftover from
        // an older build/session whose attributes are frozen at creation
        // time — e.g. an activity started before `teamAssetName` existed
        // would silently show no car forever. End those instead of reusing.
        for existing in Activity<RaceActivityAttributes>.activities {
            if existing.attributes.sessionNumber == pass.sessionNumber {
                activity = existing
                return
            }
            Task { await existing.end(nil, dismissalPolicy: .immediate) }
        }
        let attributes = RaceActivityAttributes(
            circuitName: pass.circuit.name,
            teamName: pass.team.name,
            teamColorHex: pass.team.accentHex,
            teamAssetName: pass.team.assetName,
            sessionNumber: pass.sessionNumber
        )
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let state = RaceActivityAttributes.ContentState(
            currentLap: 1,
            totalLaps: pass.totalLaps,
            startDate: startDate,
            endDate: endDate,
            awayDeadline: nil,
            redDeadline: nil
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

    /// The user left the app: start both grace countdowns (yellow, then
    /// red). This is the ONLY update sent while backgrounded — a single
    /// quick, safe call, never a held sleep. Fires an alert so the phone
    /// buzzes and the Island briefly expands before collapsing back to the
    /// compact pill.
    ///
    /// The actual yellow → red escalation is NOT driven by further app code
    /// running in the background (iOS doesn't reliably grant that — trying
    /// to hold a background-task assertion across a long sleep is what
    /// crashed this before). Instead it's purely time-based: `FlagSeverity
    /// .resolve` compares `Date.now` against these two deadlines on every
    /// redraw, so the widget self-heals to the correct state whenever the
    /// system happens to redraw it (stale-date crossing, screen wake, a
    /// tap) — no app execution required. `staleDate` is set to
    /// `awayDeadline` so the system's own staleness mechanism gives it an
    /// extra nudge to redraw around the yellow transition.
    func startAway(yellowDeadline: Date, redDeadline: Date) async {
        guard let activity else { return }
        var state = activity.content.state
        state.awayDeadline = yellowDeadline
        state.redDeadline = redDeadline
        let alert = AlertConfiguration(
            title: "🟡 Race control",
            body: "Get back to Grid before you're yellow flagged.",
            sound: .default
        )
        await activity.update(
            .init(state: state, staleDate: yellowDeadline),
            alertConfiguration: alert
        )
    }

    /// The user came back to the app. Always safe to call — this is a normal
    /// foreground update, not a background one. Clears the away state and,
    /// if they were actually flagged while gone, sends one more alert as a
    /// "welcome back" recap (expand-then-collapse) before clearing.
    func resolveOnForeground() async {
        guard let activity else { return }
        var state = activity.content.state
        let severity = FlagSeverity.resolve(
            awayDeadline: state.awayDeadline,
            redDeadline: state.redDeadline,
            isStale: activity.content.staleDate.map { Date.now >= $0 } ?? false
        )
        state.awayDeadline = nil
        state.redDeadline = nil

        switch severity {
        case .yellow:
            let alert = AlertConfiguration(
                title: "🟡 Welcome back",
                body: "You were yellow flagged while you were away.",
                sound: .default
            )
            await activity.update(.init(state: state, staleDate: state.endDate), alertConfiguration: alert)
        case .red:
            let alert = AlertConfiguration(
                title: "🔴 Welcome back",
                body: "You were red flagged — that session was at risk.",
                sound: .default
            )
            await activity.update(.init(state: state, staleDate: state.endDate), alertConfiguration: alert)
        case .warning, .none:
            // Made it back within the grace window — no alert needed.
            await activity.update(.init(state: state, staleDate: state.endDate))
        }
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
