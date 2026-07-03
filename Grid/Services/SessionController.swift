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

    private var modelContext: ModelContext?
    private let blocking = BlockingService.shared
    private let liveActivity = LiveActivityController()
    private var endTimer: Timer?
    private var lapTimer: Timer?

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

    func issuePass(circuit: Circuit, seat: Seat) {
        guard case .idle = phase else { return }
        let pass = PassDetails(
            driverName: driverName,
            circuit: circuit,
            seat: seat,
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
            seatName: pass.seat.name,
            sessionNumber: pass.sessionNumber,
            startDate: startDate,
            durationSeconds: pass.durationSeconds,
            lapSeconds: pass.circuit.lapSeconds
        ))

        await blocking.requestAuthorizationIfNeeded()
        blocking.activateShield(until: startDate.addingTimeInterval(pass.durationSeconds))
        liveActivity.start(pass: pass, startDate: startDate)
        beginRacing(pass: pass, startDate: startDate)
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
        guard let circuit = CircuitLibrary.circuit(id: snapshot.circuitID),
              let seat = circuit.seats.first(where: { $0.name == snapshot.seatName })
                ?? circuit.seats.first else {
            SharedStore.clearActiveSession()
            return
        }
        let pass = PassDetails(
            driverName: snapshot.driverName,
            circuit: circuit,
            seat: seat,
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
        endTimer = nil
        lapTimer = nil

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
            seatName: pass.seat.name,
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
        } else {
            Haptics.warning()
        }
        phase = .ended(pass, startDate: startDate, result: result)
    }
}
