import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Wraps the Screen Time stack. In simulation mode (default while the
/// FamilyControls distribution entitlement is pending, and always in the
/// Simulator) every call is a no-op so the full session flow stays testable.
@Observable
final class BlockingService {
    static let shared = BlockingService()

    var selection: FamilyActivitySelection {
        didSet { persistSelection() }
    }

    private(set) var isAuthorized = false

    private let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name(SharedConstants.managedSettingsStoreName)
    )
    private let center = DeviceActivityCenter()

    private init() {
        if let data = SharedStore.loadActivitySelection(),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        } else {
            selection = FamilyActivitySelection()
        }
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    var simulationMode: Bool {
        UserDefaults.standard.bool(forKey: "simulationMode")
    }

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        guard !simulationMode else { return true }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
        return isAuthorized
    }

    func activateShield(until endDate: Date) {
        guard !simulationMode else { return }
        store.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories =
            selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains =
            selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        scheduleBackstop(until: endDate)
    }

    func deactivateShield() {
        guard !simulationMode else { return }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        center.stopMonitoring([DeviceActivityName(SharedConstants.deviceActivityName)])
    }

    /// DeviceActivity schedule whose intervalDidEnd lifts the shield from the
    /// monitor extension even if the app is killed mid-session.
    private func scheduleBackstop(until endDate: Date) {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        // DeviceActivity requires intervals of at least 15 minutes; for shorter
        // custom sessions the app itself lifts the shield on time and the
        // backstop just runs a little long.
        let minimumEnd = Date.now.addingTimeInterval(15 * 60 + 30)
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: .now),
            intervalEnd: calendar.dateComponents(components, from: max(endDate, minimumEnd)),
            repeats: false
        )
        try? center.startMonitoring(
            DeviceActivityName(SharedConstants.deviceActivityName),
            during: schedule
        )
    }

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            SharedStore.saveActivitySelection(data)
        }
    }
}
