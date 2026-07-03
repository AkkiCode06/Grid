import SwiftUI
import UIKit

/// The locked-in screen: paddock/pit-wall view of the chosen circuit,
/// random flybys, lap-based progress on the track outline, and a shamed but
/// available DNF escape hatch.
struct RacingView: View {
    let pass: PassDetails
    let startDate: Date

    @Environment(SessionController.self) private var session

    private var endDate: Date {
        startDate.addingTimeInterval(pass.durationSeconds)
    }

    var body: some View {
        ZStack {
            backdrop
                .ignoresSafeArea()

            FlybyOverlayView(circuit: pass.circuit)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                header
                Spacer()
                telemetryPanel
                HoldToEndButton {
                    session.abandon()
                }
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled =
                UserDefaults.standard.bool(forKey: "keepScreenAwake")
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let image = AssetResolver.backdropImage(for: pass.circuit) {
            image
                .resizable()
                .scaledToFill()
        } else {
            PlaceholderBackdropView(circuit: pass.circuit)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(pass.circuit.name.uppercased())
                .font(.telemetry(13, weight: .bold))
                .kerning(3)
                .foregroundStyle(Theme.textPrimary)
            Text("\(pass.team.name.uppercased()) • \(pass.sessionLabel)")
                .font(.telemetry(10))
                .kerning(2)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 12)
        .shadow(color: .black.opacity(0.6), radius: 6)
    }

    private var telemetryPanel: some View {
        TimelineView(.periodic(from: startDate, by: 1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startDate))
            let progress = min(1, elapsed / pass.durationSeconds)
            let lap = min(pass.totalLaps, Int(elapsed / pass.circuit.lapSeconds) + 1)

            VStack(spacing: 14) {
                ZStack {
                    TrackOutlineShape(circuitID: pass.circuit.id)
                        .stroke(
                            Color.white.opacity(0.18),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                    TrackOutlineShape(circuitID: pass.circuit.id)
                        .trim(from: 0, to: progress)
                        .stroke(
                            Theme.raceRed,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                }
                .aspectRatio(1.4, contentMode: .fit)
                .frame(maxHeight: 110)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LAP")
                            .font(.telemetry(10))
                            .kerning(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(lap)/\(pass.totalLaps)")
                            .font(.telemetry(30, weight: .black))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("REMAINING")
                            .font(.telemetry(10))
                            .kerning(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text(timerInterval: startDate...endDate, countsDown: true)
                            .font(.telemetry(30, weight: .black))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding(18)
            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

/// Gradient sky + trackside silhouette shown until real backdrop art lands.
struct PlaceholderBackdropView: View {
    let circuit: Circuit

    var body: some View {
        ZStack {
            LinearGradient(
                colors: circuit.skyColors.map { Color(hex: $0) },
                startPoint: .top,
                endPoint: .bottom
            )
            VStack {
                Spacer()
                // Catch fence + grandstand silhouette.
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(.black.opacity(0.85))
                    HStack(spacing: 22) {
                        ForEach(0..<12, id: \.self) { _ in
                            Rectangle()
                                .fill(.white.opacity(0.06))
                                .frame(width: 2)
                        }
                    }
                    .frame(height: 60)
                    .offset(y: -60)
                }
                .frame(height: 180)
            }
        }
        .ignoresSafeArea()
    }
}

/// Press-and-hold-3s escape hatch. Ending early is allowed — but it's a DNF.
struct HoldToEndButton: View {
    let action: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var isPressing = false

    private let holdDuration: TimeInterval = 3

    var body: some View {
        Text(isPressing ? "KEEP HOLDING TO RETIRE…" : "HOLD TO END SESSION (DNF)")
            .font(.telemetry(11, weight: .semibold))
            .kerning(1.5)
            .foregroundStyle(isPressing ? Theme.raceRed : Theme.textTertiary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.raceRed.opacity(0.25))
                        .frame(width: geo.size.width * holdProgress)
                }
            )
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
                Haptics.warning()
                action()
            } onPressingChanged: { pressing in
                isPressing = pressing
                if pressing {
                    Haptics.impact(.light)
                    withAnimation(.linear(duration: holdDuration)) {
                        holdProgress = 1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        holdProgress = 0
                    }
                }
            }
    }
}
