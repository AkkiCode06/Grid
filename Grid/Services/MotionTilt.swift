import Foundation
import CoreMotion

/// Publishes smoothed device tilt for the gyro-reactive pass. Start/stop it
/// with the screen that uses it so the gyro isn't running all the time.
/// Values are relative to the attitude when tracking started, so however
/// the user is holding the phone becomes the neutral position.
@Observable
final class MotionTilt {
    static let shared = MotionTilt()

    /// Left/right tilt in radians, roughly -0.6...0.6 after clamping.
    private(set) var roll: Double = 0
    /// Forward/back tilt in radians, same range.
    private(set) var pitch: Double = 0

    private let manager = CMMotionManager()
    private var referenceRoll: Double?
    private var referencePitch: Double?

    private init() {}

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        referenceRoll = nil
        referencePitch = nil
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }
            if referenceRoll == nil {
                referenceRoll = attitude.roll
                referencePitch = attitude.pitch
            }
            let rawRoll = attitude.roll - (referenceRoll ?? 0)
            let rawPitch = attitude.pitch - (referencePitch ?? 0)
            // Low-pass for smoothness, clamp so the effect stays subtle.
            roll = roll * 0.8 + max(-0.6, min(0.6, rawRoll)) * 0.2
            pitch = pitch * 0.8 + max(-0.6, min(0.6, rawPitch)) * 0.2
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        roll = 0
        pitch = 0
    }
}
