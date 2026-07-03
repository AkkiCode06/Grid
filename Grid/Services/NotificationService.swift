import Foundation
import UserNotifications

/// Race-control flags for wandering off mid-session: a yellow flag shortly
/// after leaving the app, a red flag if the user stays away too long. Both
/// are pre-scheduled the moment the app backgrounds (we can't run code while
/// suspended) and cancelled on return.
enum NotificationService {
    private static let yellowID = "grid.flag.yellow"
    private static let redID = "grid.flag.red"

    static let yellowDelay: TimeInterval = 15
    static let redDelay: TimeInterval = 120

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    static func scheduleFlagAlerts() {
        let center = UNUserNotificationCenter.current()

        let yellow = UNMutableNotificationContent()
        yellow.title = "🟡 Yellow flag"
        yellow.body = "You've wandered out of the paddock. Get back to your session."
        yellow.sound = .default
        center.add(UNNotificationRequest(
            identifier: yellowID,
            content: yellow,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: yellowDelay, repeats: false)
        ))

        let red = UNMutableNotificationContent()
        red.title = "🔴 Red flag"
        red.body = "You've been gone too long — the session is at risk. Return to Grid."
        red.sound = .default
        center.add(UNNotificationRequest(
            identifier: redID,
            content: red,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: redDelay, repeats: false)
        ))
    }

    static func cancelFlagAlerts() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [yellowID, redID])
    }
}
