import DeviceActivity
import ManagedSettings

/// Backstop: lifts the shield when the scheduled session interval ends, even
/// if the app was killed mid-session. The snapshot is intentionally left in
/// place so the app can stamp the pass FINISHED on next launch.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name(SharedConstants.managedSettingsStoreName)
    )

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == DeviceActivityName(SharedConstants.deviceActivityName) else { return }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
