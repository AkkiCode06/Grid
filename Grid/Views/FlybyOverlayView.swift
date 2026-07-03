import SwiftUI
import AVFoundation

/// Fires a car flyby at random 20–60s intervals. A bundled video clip for
/// the circuit wins if one exists; otherwise the 3D team-liveried car
/// crosses the screen — so the app needs zero video assets to feel alive.
struct FlybyOverlayView: View {
    let circuit: Circuit
    let team: Team

    @State private var activeClipURL: URL?
    @State private var carTrigger = 0

    private var clipURLs: [URL] {
        AssetResolver.flybyClipURLs(for: circuit)
    }

    private var isUITest: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-uitest-flyby")
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            if let url = activeClipURL {
                FlybyVideoPlayerView(url: url) {
                    activeClipURL = nil
                }
                .transition(.opacity)
            }
            CarFlybySceneView(trigger: carTrigger, team: team)
        }
        .task {
            // First flyby comes quickly so the screen feels alive, then
            // settles into the random 20–60s cadence.
            var delay = isUITest ? 2.0 : Double.random(in: 8...18)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }
                fireFlyby()
                delay = isUITest ? 5.0 : Double.random(in: 20...60)
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
            carTrigger += 1
        }
        Haptics.impact(.soft)
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
