import SwiftUI

/// Authentic five-light start: columns illuminate one per second, hold for a
/// random 0.2–3s, then lights out — and the session (plus the shield) begins.
struct LightsOutView: View {
    @Environment(SessionController.self) private var session

    @State private var litColumns = 0
    @State private var lightsOut = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 48) {
                gantry
                Text(lightsOut ? "GO GO GO" : " ")
                    .font(.telemetry(18, weight: .black))
                    .kerning(6)
                    .foregroundStyle(Theme.gold)
                    .opacity(lightsOut ? 1 : 0)
            }
        }
        .task {
            await runSequence()
        }
    }

    private var gantry: some View {
        HStack(spacing: 18) {
            ForEach(0..<5, id: \.self) { column in
                VStack(spacing: 14) {
                    ForEach(0..<2, id: \.self) { _ in
                        lightBulb(on: !lightsOut && column < litColumns)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 10)
                .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func lightBulb(on: Bool) -> some View {
        Circle()
            .fill(on ? Theme.raceRed : Color(white: 0.15))
            .frame(width: 34, height: 34)
            .shadow(color: on ? Theme.raceRed.opacity(0.9) : .clear, radius: 12)
            .animation(.easeOut(duration: 0.12), value: on)
    }

    private func runSequence() async {
        // The bundled F1 lights recording carries the whole audio; the
        // visuals and haptics are timed to it.
        SoundPlayer.shared.play("lights_sequence")
        try? await Task.sleep(for: .seconds(0.8))
        for column in 1...5 {
            litColumns = column
            Haptics.impact(.rigid)
            try? await Task.sleep(for: .seconds(1))
        }
        // The random hold is what makes a real start unpredictable.
        try? await Task.sleep(for: .seconds(Double.random(in: 0.2...3.0)))
        lightsOut = true
        // GO GO GO — alarm-style haptic burst, ramping hard.
        for i in 0..<12 {
            Haptics.impact(i % 3 == 2 ? .heavy : .rigid)
            try? await Task.sleep(for: .milliseconds(i < 6 ? 90 : 60))
        }
        Haptics.success()
        Haptics.impact(.heavy)
        try? await Task.sleep(for: .seconds(0.6))
        await session.lightsOut()
    }
}
