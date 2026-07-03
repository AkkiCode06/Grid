import SwiftUI
import AVFoundation

/// Fires a car flyby at random 20–60s intervals. Plays a bundled clip for
/// the circuit when available; until real clips land, falls back to a
/// motion-streak placeholder so the effect (and its timing) is testable now.
struct FlybyOverlayView: View {
    let circuit: Circuit

    @State private var activeClipURL: URL?
    @State private var streakTrigger = 0

    private var clipURLs: [URL] {
        AssetResolver.flybyClipURLs(for: circuit)
    }

    var body: some View {
        ZStack {
            if let url = activeClipURL {
                FlybyVideoPlayerView(url: url) {
                    activeClipURL = nil
                }
                .transition(.opacity)
            }
            FlybyStreakView(trigger: streakTrigger)
        }
        .task {
            // First flyby comes quickly so the screen feels alive, then
            // settles into the random 20–60s cadence.
            var delay = Double.random(in: 8...18)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }
                fireFlyby()
                delay = Double.random(in: 20...60)
            }
        }
    }

    private func fireFlyby() {
        SoundPlayer.shared.play("whoosh")
        if let url = clipURLs.randomElement() {
            withAnimation(.easeIn(duration: 0.15)) {
                activeClipURL = url
            }
        } else {
            streakTrigger += 1
        }
        Haptics.impact(.soft)
    }
}

/// Placeholder flyby: a bright streak crossing the lower third of the screen.
struct FlybyStreakView: View {
    let trigger: Int

    @State private var phase: CGFloat = -0.5

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.9), Theme.raceRed.opacity(0.7), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * 0.5, height: 7)
                .blur(radius: 2)
                .position(
                    x: phase * geo.size.width,
                    y: geo.size.height * 0.68
                )
                .opacity(phase > -0.4 && phase < 1.6 ? 1 : 0)
        }
        .onChange(of: trigger) { _, _ in
            phase = -0.5
            withAnimation(.easeIn(duration: 0.7)) {
                phase = 1.7
            }
        }
    }
}

/// Full-bleed, muted AVPlayerLayer for a single flyby clip; calls `onFinish`
/// when the clip ends so the overlay can be torn down.
struct FlybyVideoPlayerView: UIViewRepresentable {
    let url: URL
    let onFinish: () -> Void

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.play(url: url, onFinish: onFinish)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    final class PlayerContainerView: UIView {
        private var player: AVPlayer?
        private var endObserver: NSObjectProtocol?

        override static var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        func play(url: URL, onFinish: @escaping () -> Void) {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = true
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            self.player = player

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                onFinish()
            }
            player.play()
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }
}
