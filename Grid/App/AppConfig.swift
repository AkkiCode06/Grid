import Foundation

enum AppConfig {
    /// Grid Pro subscription product IDs (see Grid.storekit for local testing).
    static let proYearlyProductID = "com.akki.grid.pro.yearly"
    static let proMonthlyProductID = "com.akki.grid.pro.monthly"
    static var proProductIDs: [String] { [proYearlyProductID, proMonthlyProductID] }

    /// Legacy one-time unlock ID, still honoured if a user owns it.
    static let fullUnlockProductID = "com.akki.grid.unlock.full"

    /// Every product ID that grants full access.
    static var unlockingProductIDs: Set<String> {
        Set(proProductIDs + [fullUnlockProductID])
    }

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
