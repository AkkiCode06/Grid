import SwiftUI

/// The commit ritual: hold to imprint the pass (name + timestamp emboss with
/// a haptic hit, then a hologram shimmer), which locks the session in and
/// hands off to the lights-out sequence.
struct PaddockPassView: View {
    let pass: PassDetails
    @Environment(SessionController.self) private var session

    @State private var stamped = false
    @State private var shimmer = false
    @State private var isPressing = false
    @State private var holdProgress: CGFloat = 0

    private let holdDuration: TimeInterval = 1.2

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    guard !stamped else { return }
                    session.cancelPass()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(stamped ? Theme.textTertiary : Theme.textPrimary)
                }
                .disabled(stamped)
                Spacer()
            }
            .padding(.horizontal, 24)

            Spacer()

            PassCardView(
                model: PassCardModel(pass: pass),
                stamped: stamped,
                shimmer: shimmer,
                motionShine: true
            )
            .padding(.horizontal, 28)
            .scaleEffect(isPressing && !stamped ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: isPressing)
            .onAppear { MotionTilt.shared.start() }
            .onDisappear { MotionTilt.shared.stop() }

            Spacer()

            Text(stamped ? "PASS STAMPED — HEAD TO THE GRID" : "HOLD TO STAMP YOUR PASS")
                .font(.telemetry(12))
                .kerning(2)
                .foregroundStyle(stamped ? Theme.gold : Theme.textSecondary)

            holdButton
                .padding(.bottom, 32)
        }
        .background(Theme.background)
    }

    private var holdButton: some View {
        ZStack {
            Circle()
                .stroke(Theme.cardHighlight, lineWidth: 5)
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    Theme.raceRed,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: stamped ? "checkmark" : "hand.point.down.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(stamped ? Theme.gold : Theme.textPrimary)
        }
        .frame(width: 84, height: 84)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
            commit()
        } onPressingChanged: { pressing in
            guard !stamped else { return }
            isPressing = pressing
            if pressing {
                Haptics.impact(.light)
                withAnimation(.linear(duration: holdDuration)) {
                    holdProgress = 1
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    holdProgress = 0
                }
            }
        }
        .disabled(stamped)
    }

    private func commit() {
        guard !stamped else { return }
        stamped = true
        holdProgress = 1
        Haptics.impact(.heavy)
        SoundPlayer.shared.play("stamp")

        // Emboss lands, then the hologram sweep, then hand off to the lights.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            shimmer = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            session.commitPass()
        }
    }
}
