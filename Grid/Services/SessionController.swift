import Foundation
import SwiftData
import SwiftUI

/// Drives the session state machine:
/// idle → passIssued → lightsSequence → racing → ended → idle
///
/// The racing phase is persisted to the App Group as an ActiveSessionSnapshot
/// so a killed app resumes (or finalises) the session on relaunch, and the
/// widget/monitor extensions can see it.
@Observable
final class SessionController {
    private(set) var phase: SessionPhase = .idle

    private(set) var pitUntil: Date?
    private(set) var pitStopUsed = false

    private var modelContext: ModelContext?
    private let blocking = BlockingService.shared
    private let liveActivity = LiveActivityController()
    private var endTimer: Timer?
    private var lapTimer: Timer?
    private var pitTimer: Timer?
    private var awaySince: Date?

    var driverName: String {
        let stored = UserDefaults.standard.string(forKey: "driverName") ?? ""
        return stored.isEmpty ? "DRIVER" : stored
    }

    var customDurationMinutes: Int {
        get { max(5, UserDefaults.standard.integer(forKey: "customDurationMinutes")) }
        set { UserDefaults.standard.set(newValue, forKey: "customDurationMinutes") }
    }

    func attachModelContext(_ context: ModelContext) {
        modelContext = context
    }

    // MARK: - Flow

    func issuePass(circuit: Circuit, team: Team) {
        guard case .idle = phase else { return }
        let pass = PassDetails(
            driverName: driverName,
            circuit: circuit,
            team: team,
            issuedAt: .now,
            sessionNumber: SharedStore.nextSessionNumber,
            durationSeconds: circuit.duration(customMinutes: customDurationMinutes)
        )
        phase = .passIssued(pass)
    }

    func cancelPass() {
        guard case .passIssued = phase else { return }
        phase = .idle
    }

    /// The imprint/stamp on the pass is the commit action.
    func commitPass() {
        guard case .passIssued(let pass) = phase else { return }
        SharedStore.consumeSessionNumber()
        phase = .lightsSequence(pass)
    }

    /// Called when the five lights go out: shield on, session running.
    func lightsOut() async {
        guard case .lightsSequence(let pass) = phase else { return }
        let startDate = Date.now

        SharedStore.saveActiveSession(ActiveSessionSnapshot(
            driverName: pass.driverName,
            circuitID: pass.circuit.id,
            circuitName: pass.circuit.name,
            teamName: pass.team.name,
            sessionNumber: pass.sessionNumber,
            startDate: startDate,
            durationSeconds: pass.durationSeconds,
            lapSeconds: pass.circuit.lapSeconds
        ))

        await blocking.requestAuthorizationIfNeeded()
        await NotificationService.requestAuthorization()
        blocking.activateShield(until: startDate.addingTimeInterval(pass.durationSeconds))
        liveActivity.start(pass: pass, startDate: startDate)
        beginRacing(pass: pass, startDate: startDate)
    }

    // MARK: - Pit stop (one per session)

    func enterPitStop(minutes: Int) {
        guard case .racing(let pass, let startDate) = phase,
              pitUntil == nil, !pitStopUsed else { return }
        let pitSeconds = TimeInterval(minutes * 60)
        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let until = min(Date.now.addingTimeInterval(pitSeconds), endDate)
        pitStopUsed = true
        pitUntil = until
        blocking.deactivateShield()
        pitTimer?.invalidate()
        pitTimer = Timer.scheduledTimer(
            withTimeInterval: max(1, until.timeIntervalSinceNow), repeats: false
        ) { _ in
            Task { @MainActor in
                self.exitPitStop()
            }
        }
    }

    func exitPitStop() {
        guard case .racing(let pass, let startDate) = phase, pitUntil != nil else { return }
        pitUntil = nil
        pitTimer?.invalidate()
        pitTimer = nil
        blocking.activateShield(until: startDate.addingTimeInterval(pass.durationSeconds))
        Haptics.impact(.rigid)
    }

    /// Leaving the app mid-session waves flags: the Live Activity goes
    /// yellow immediately, and pre-scheduled notifications escalate to red
    /// if the user stays away. The Live Activity's stale date is set so
    /// WidgetKit renders the red flag automatically after `redDelay`.
    /// Everything clears when they return.
    func handleScenePhase(_ scenePhase: ScenePhase) {
        guard case .racing = phase else { return }
        switch scenePhase {
        case .background:
            guard pitUntil == nil else { return } // pit stop = licensed to leave
            awaySince = .now
            NotificationService.scheduleFlagAlerts()
            Task(priority: .userInitiated) {
                // Set yellow flag with a stale date that triggers the red
                // escalation in the widget once the user has been away too long.
                await liveActivity.setFlag(
                    "yellow",
                    staleDate: Date.now.addingTimeInterval(NotificationService.redDelay)
                )
            }
        case .active:
            NotificationService.cancelFlagAlerts()
            if let away = awaySince {
                let elapsed = Date.now.timeIntervalSince(away)
                awaySince = nil
                if elapsed >= NotificationService.redDelay {
                    // They were gone long enough to trigger a red flag — flash
                    // it briefly so the user sees the escalation before clearing.
                    Task {
                        await liveActivity.setFlag("red")
                        try? await Task.sleep(for: .milliseconds(600))
                        await liveActivity.setFlag(nil)
                    }
                } else {
                    Task {
                        await liveActivity.setFlag(nil)
                    }
                }
            }
            tick()
        default:
            break
        }
    }

    /// Early exit — allowed, but the pass is stamped DNF.
    func abandon() {
        guard case .racing(let pass, let startDate) = phase else { return }
        end(pass: pass, startDate: startDate, result: .dnf)
    }

    /// Return to the paddock after the ended screen.
    func dismissEnded() {
        guard case .ended = phase else { return }
        phase = .idle
    }

    // MARK: - Restore / clock

    /// Called on launch. Resumes a live session or finalises one that ran to
    /// completion while the app was dead.
    func restoreOnLaunch() {
        guard case .idle = phase, let snapshot = SharedStore.loadActiveSession() else { return }
        guard let circuit = CircuitLibrary.circuit(id: snapshot.circuitID) else {
            SharedStore.clearActiveSession()
            return
        }
        let team = TeamLibrary.team(named: snapshot.teamName) ?? TeamLibrary.all[0]
        let pass = PassDetails(
            driverName: snapshot.driverName,
            circuit: circuit,
            team: team,
            issuedAt: snapshot.startDate,
            sessionNumber: snapshot.sessionNumber,
            durationSeconds: snapshot.durationSeconds
        )
        if Date.now < snapshot.endDate {
            beginRacing(pass: pass, startDate: snapshot.startDate)
        } else {
            end(pass: pass, startDate: snapshot.startDate, result: .finished)
        }
    }

    /// Re-check the clock (called when the scene becomes active and as a
    /// fallback from the racing screen).
    func tick() {
        guard case .racing(let pass, let startDate) = phase else { return }
        if Date.now >= startDate.addingTimeInterval(pass.durationSeconds) {
            end(pass: pass, startDate: startDate, result: .finished)
        } else {
            updateLiveActivityLap(pass: pass, startDate: startDate)
        }
    }

    // MARK: - Internals

    private func beginRacing(pass: PassDetails, startDate: Date) {
        phase = .racing(pass, startDate: startDate)
        scheduleTimers(pass: pass, startDate: startDate)
    }

    private func scheduleTimers(pass: PassDetails, startDate: Date) {
        endTimer?.invalidate()
        lapTimer?.invalidate()

        let endDate = startDate.addingTimeInterval(pass.durationSeconds)
        let remaining = max(0.5, endDate.timeIntervalSinceNow)
        endTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
        // Keep the Live Activity's lap counter fresh while the app is alive.
        lapTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { @MainActor in
                guard case .racing(let pass, let startDate) = self.phase else { return }
                self.updateLiveActivityLap(pass: pass, startDate: startDate)
            }
        }
    }

    private func updateLiveActivityLap(pass: PassDetails, startDate: Date) {
        let elapsed = Date.now.timeIntervalSince(startDate)
        let lap = min(pass.totalLaps, Int(elapsed / pass.circuit.lapSeconds) + 1)
        Task {
            await liveActivity.updateLap(lap, pass: pass, startDate: startDate)
        }
    }

    private func end(pass: PassDetails, startDate: Date, result: RaceResult) {
        endTimer?.invalidate()
        lapTimer?.invalidate()
        pitTimer?.invalidate()
        endTimer = nil
        lapTimer = nil
        pitTimer = nil
        pitUntil = nil
        pitStopUsed = false
        awaySince = nil
        NotificationService.cancelFlagAlerts()

        blocking.deactivateShield()
        Task {
            await liveActivity.end()
        }
        SharedStore.clearActiveSession()

        let completed = min(pass.durationSeconds, max(0, Date.now.timeIntervalSince(startDate)))
        let record = RaceRecord(
            driverName: pass.driverName,
            circuitID: pass.circuit.id,
            circuitName: pass.circuit.name,
            teamName: pass.team.name,
            sessionNumber: pass.sessionNumber,
            startDate: startDate,
            plannedSeconds: pass.durationSeconds,
            completedSeconds: completed,
            lapSeconds: pass.circuit.lapSeconds,
            result: result
        )
        modelContext?.insert(record)
        try? modelContext?.save()

        if result == .finished {
            Haptics.success()
            // Track completed races for win-bonus in the tracker
            let count = UserDefaults.standard.integer(forKey: "completedRaceCount")
            UserDefaults.standard.set(count + 1, forKey: "completedRaceCount")
        } else {
            Haptics.warning()
        }
        phase = .ended(pass, startDate: startDate, result: result)
    }
}
