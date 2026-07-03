import AVFoundation
import Foundation

/// Plays short SFX (whoosh, light beeps). No-ops gracefully when the audio
/// asset isn't bundled yet, so the app is fully runnable before assets land.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    private init() {}

    func play(_ name: String) {
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        configureSessionIfNeeded()
        guard let player = player(for: name) else { return }
        player.currentTime = 0
        player.play()
    }

    /// Play these moments over the ringer/silent switch — they're
    /// intentional, not incidental UI blips.
    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func player(for name: String) -> AVAudioPlayer? {
        if let cached = players[name] { return cached }
        let url = Bundle.main.url(forResource: name, withExtension: "m4a")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
        guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[name] = player
        return player
    }
}
