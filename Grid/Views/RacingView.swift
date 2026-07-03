import SwiftUI
import UIKit

/// The locked-in screen, driver-tracker style: the real circuit outline with
/// the user ("YOU") and a field of fictional rivals circulating live, an
/// F1-style session clock up top, and pit-stop/DNF controls at the bottom.
/// Behind it all, a photorealistic MapKit flyover of the actual circuit.
/// Adapts between portrait and landscape.
struct RacingView: View {
    let pass: PassDetails
    let startDate: Date

    @Environment(SessionController.self) private var session
    @State private var showingPitPicker = false

    private var endDate: Date {
        startDate.addingTimeInterval(pass.durationSeconds)
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                background

                if isLandscape {
                    HStack(spacing: 0) {
                        VStack(spacing: 16) {
                            header
                            Spacer()
                            controls
                        }
                        .frame(width: geo.size.width * 0.34)
                        .padding(.vertical, 16)
                        .padding(.leading, 8)

                        TrackerView(pass: pass, startDate: startDate)
                            .padding(12)
                    }
                } else {
                    VStack(spacing: 0) {
                        header
                            .padding(.top, 8)
                        TrackerView(pass: pass, startDate: startDate)
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal, 8)
                        controls
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled =
                UserDefaults.standard.bool(forKey: "keepScreenAwake")
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if CircuitGeo.coordinates(for: pass.circuit.id) != nil {
            CircuitFlyoverView(
                circuitID: pass.circuit.id,
                isPaused: session.pitUntil != nil,
                dualMode: false
            )
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.45).ignoresSafeArea())
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.75), .clear, .clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        } else {
            LinearGradient(
                colors: pass.circuit.skyColors.map { Color(hex: $0).opacity(0.35) },
                startPoint: .top,
                endPoint: .bottom
            )
            .background(Theme.background)
            .ignoresSafeArea()
        }
    }

    // MARK: - Header (F1-style session clock)

    private var header: some View {
        VStack(spacing: 6) {
            Text(pass.circuit.name.uppercased())
                .font(.gilroy(12, .light))
                .kerning(3)
                .foregroundStyle(.white.opacity(0.65))

            if let pitUntil = session.pitUntil {
                VStack(spacing: 2) {
                    Text("PIT STOP")
                        .font(.gilroy(13, .black))
                        .kerning(3)
                        .foregroundStyle(.yellow)
                    Text(timerInterval: Date.now...pitUntil, countsDown: true)
                        .font(.gilroy(40, .heavy))
                        .foregroundStyle(.yellow)
                }
            } else {
                Text(timerInterval: startDate...endDate, countsDown: true)
                    .font(.gilroy(46, .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                TimelineView(.periodic(from: startDate, by: 1)) { context in
                    let elapsed = max(0, context.date.timeIntervalSince(startDate))
                    let lap = min(pass.totalLaps, Int(elapsed / pass.circuit.lapSeconds) + 1)
                    Text("LAP \(lap)/\(pass.totalLaps)")
                        .font(.gilroy(12, .bold))
                        .kerning(1.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.raceRed, in: Capsule())
                        .foregroundStyle(.white)
                }
                Text(pass.sessionLabel)
                    .font(.gilroy(12, .medium))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 8)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            pitButton
            HoldToEndButton {
                session.abandon()
            }
        }
    }

    @ViewBuilder
    private var pitButton: some View {
        if session.pitUntil != nil {
            Button {
                session.exitPitStop()
            } label: {
                Label("EXIT PIT", systemImage: "flag.fill")
                    .font(.gilroy(12, .bold))
                    .kerning(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.yellow, lineWidth: 1.5)
                    )
                    .foregroundStyle(.yellow)
            }
        } else if showingPitPicker {
            HStack(spacing: 0) {
                ForEach([5, 10, 15], id: \.self) { mins in
                    Button {
                        Haptics.impact(.medium)
                        showingPitPicker = false
                        session.enterPitStop(minutes: mins)
                    } label: {
                        Text("\(mins)M")
                            .font(.gilroy(12, .bold))
                            .kerning(1)
                            .frame(width: 44, height: 38)
                    }
                    if mins != 15 {
                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))
                    }
                }
            }
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.yellow.opacity(0.8), lineWidth: 1.5)
            )
            .foregroundStyle(.yellow)
        } else {
            Button {
                Haptics.impact(.light)
                withAnimation { showingPitPicker = true }
            } label: {
                Label(
                    session.pitStopUsed ? "PIT USED" : "PIT STOP",
                    systemImage: "wrench.and.screwdriver.fill"
                )
                .font(.gilroy(12, .bold))
                .kerning(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            session.pitStopUsed ? Color.white.opacity(0.15) : .yellow.opacity(0.8),
                            lineWidth: 1.5
                        )
                )
                .foregroundStyle(session.pitStopUsed ? Theme.textTertiary : .yellow)
            }
            .disabled(session.pitStopUsed)
        }
    }
}

// MARK: - Live tracker

/// The driver-tracker: real circuit outline with the user and rivals
/// circulating as tagged dots, F1-TV style.
struct TrackerView: View {
    let pass: PassDetails
    let startDate: Date

    private let inset: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size).insetBy(dx: inset, dy: inset)
            let track = TrackGeometry(circuitID: pass.circuit.id, in: rect)

            TimelineView(.animation(minimumInterval: 1.0 / 12)) { context in
                let elapsed = max(0, context.date.timeIntervalSince(startDate))
                let sessionProgress = min(1, elapsed / pass.durationSeconds)

                // User gets 1% faster lap time for every completed race (capped at 15%)
                let winBonus = min(0.15, Double(UserDefaults.standard.integer(forKey: "completedRaceCount")) * 0.01)
                let userLap = pass.circuit.lapSeconds * (1.0 - winBonus)
                let userFraction = (elapsed / userLap).truncatingRemainder(dividingBy: 1)

                ZStack {
                    // Track ribbon
                    TrackOutlineShape(circuitID: pass.circuit.id)
                        .stroke(
                            .white.opacity(0.22),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                        )
                        .padding(inset)
                    // Session progress fill
                    TrackOutlineShape(circuitID: pass.circuit.id)
                        .trim(from: 0, to: sessionProgress)
                        .stroke(
                            Theme.raceRed.opacity(0.85),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                        )
                        .padding(inset)

                    // Rivals
                    ForEach(RivalGrid.all) { rival in
                        let fraction = rival.lapFraction(
                            elapsed: elapsed,
                            lapSeconds: pass.circuit.lapSeconds,
                            sessionSeed: pass.sessionNumber
                        )
                        CarMarker(
                            code: rival.code,
                            color: Color(hex: rival.colorHex),
                            isUser: false
                        )
                        .position(track.point(at: fraction))
                    }

                    // The user
                    CarMarker(
                        code: "YOU",
                        color: Color(hex: PassThemeStore.shared.theme.accentHex),
                        isUser: true
                    )
                    .position(track.point(at: userFraction))
                }
            }
        }
    }
}

/// F1-TV style marker: coloured dot with a three-letter tag.
struct CarMarker: View {
    let code: String
    let color: Color
    let isUser: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(code)
                .font(.gilroy(isUser ? 11 : 9, isUser ? .black : .bold))
                .kerning(0.5)
                .padding(.horizontal, isUser ? 7 : 5)
                .padding(.vertical, 2.5)
                .background(.black.opacity(0.65), in: Capsule())
                .foregroundStyle(isUser ? .white : .white.opacity(0.85))
                .overlay(
                    Capsule().strokeBorder(
                        isUser ? color : .clear, lineWidth: 1.5
                    )
                )
            Circle()
                .fill(color)
                .frame(width: isUser ? 15 : 11, height: isUser ? 15 : 11)
                .overlay(
                    Circle().strokeBorder(
                        .white, lineWidth: isUser ? 2.5 : 1.5
                    )
                )
                .shadow(color: color.opacity(0.8), radius: isUser ? 6 : 3)
        }
        .offset(y: -12)
    }
}

/// Press-and-hold-3s escape hatch. Ending early is allowed — but it's a DNF.
struct HoldToEndButton: View {
    let action: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var isPressing = false

    private let holdDuration: TimeInterval = 3

    var body: some View {
        Text(isPressing ? "KEEP HOLDING…" : "HOLD FOR DNF")
            .font(.gilroy(12, .bold))
            .kerning(1.5)
            .foregroundStyle(isPressing ? Theme.raceRed : Theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.raceRed.opacity(0.3))
                        .frame(width: geo.size.width * holdProgress)
                }
            )
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.raceRed.opacity(0.6), lineWidth: 1.5)
            )
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
