import Foundation

enum AppConfig {
    /// Product ID for the one-time full unlock. Configurable before launch.
    static let fullUnlockProductID = "com.akki.grid.unlock.full"

    /// Grace period after leaving the app before the yellow flag drops.
    static let flagGraceSeconds: TimeInterval = 20

    /// Further time away, after the yellow flag, before it escalates to red.
    static let redFlagGraceSeconds: TimeInterval = 40

    /// While the FamilyControls distribution entitlement is pending, the whole
    /// session flow runs without applying a real shield. The live value is the
    /// "simulationMode" UserDefaults key (toggleable in Settings); this is
    /// just its default.
    static var simulationModeDefault: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return true // flip to false once the entitlement is granted
        #endif
    }

    static func registerDefaultPreferences() {
        UserDefaults.standard.register(defaults: [
            "soundEnabled": true,
            "keepScreenAwake": true,
            "simulationMode": simulationModeDefault,
            "driverName": "",
            "customDurationMinutes": 30,
        ])
    }
}
