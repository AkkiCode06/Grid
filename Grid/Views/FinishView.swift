/// Session end, staged:
/// - **finished**: results/classification screen → Continue → cross-fade to
///   the pass stamped FINISHED → auto-fade back to the paddock.
/// - **dnf**: the pass is snipped in two and falls apart, then auto-returns.
import SwiftUI

private enum FinishStage {
    case results   // classification (finish) or DNF headline
    case pass      // stamped pass, briefly, before auto-return
}

struct FinishView: View {
    let pass: PassDetails
    let startDate: Date
    let result: RaceResult

    @Environment(SessionController.self) private var session
    @State private var stage: FinishStage = .results
    @State private var snip = false
    @State private var didAppear = false

    private var completedMinutes: Int {
        let completed = min(pass.durationSeconds, Date.now.timeIntervalSince(startDate))
        return max(0, Int(completed / 60))
    }

    private var bonusForThisRace: Int {
        let count = UserDefaults.standard.integer(forKey: "completedRaceCount")
        return result == .finished ? max(0, count - 1) : count
    }

    private var simulation: RaceSimulation {
        RaceSimulation(
            seed: pass.sessionNumber,
            duration: pass.durationSeconds,
            lapSeconds: pass.circuit.lapSeconds
        )
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch stage {
            case .results:
                if result == .finished {
                    resultsScreen.transition(.opacity)
                } else {
                    dnfScreen.transition(.opacity)
                }
            case .pass:
                passScreen.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: stage)
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            // Race-over haptic first.
            if result == .finished {
                Haptics.success()
            } else {
                Haptics.warning()
                // Kick off the snip after the headline reads.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    Haptics.impact(.rigid)
                    withAnimation(.easeIn(duration: 0.7)) { snip = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
                    session.dismissEnded()
                }
            }
        }
    }

    // MARK: - Finished: results

    private var resultsScreen: some View {
        ScrollView {
            VStack(spacing: 20) {
                ChequeredFlagView()
                    .frame(height: 100)
                    .padding(.top, 16)
                Text("CHEQUERED FLAG")
                    .font(.gilroy(16, .black))
                    .kerning(4)
                    .foregroundStyle(Theme.gold)

                ClassificationView(
                    order: simulation.finishingOrder(userBonus: bonusForThisRace),
                    bestLaps: simulation.bestLaps(
                        for: simulation.finishingOrder(userBonus: bonusForThisRace)
                    ),
                    userColorHex: PassThemeStore.shared.theme.accentHex
                )
                .padding(.horizontal, 20)

                Text("\(pass.totalLaps) LAPS • \(completedMinutes) MIN LOCKED IN • +1 GRID LUCK")
                    .font(.gilroy(11, .medium))
                    .kerning(1.5)
                    .foregroundStyle(Theme.textSecondary)

                Button {
                    Haptics.impact(.medium)
                    withAnimation { stage = .pass }
                    // Pass lingers, then auto-returns to the grid.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                        session.dismissEnded()
                    }
                } label: {
                    Text("CONTINUE")
                        .font(.gilroy(15, .bold))
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.raceRed, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Finished: pass card (auto-returns)

    private var passScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            PassCardView(
                model: PassCardModel(pass: pass),
                stamped: true,
                result: .finished
            )
            .padding(.horizontal, 44)
            Text("FILED IN YOUR RACE LOG")
                .font(.gilroy(11, .bold))
                .kerning(2)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }

    // MARK: - DNF: snipped pass

    private var dnfScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "flag.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.raceRed)
            Text("DID NOT FINISH")
                .font(.gilroy(16, .black))
                .kerning(4)
                .foregroundStyle(Theme.raceRed)
            Text("RETIRED AFTER \(completedMinutes) MIN — UNCLASSIFIED")
                .font(.gilroy(11, .medium))
                .kerning(2)
                .foregroundStyle(Theme.textSecondary)

            SnippedPassView(
                model: PassCardModel(pass: pass),
                snip: snip
            )
            .padding(.horizontal, 44)
            .padding(.top, 8)

            Spacer()
        }
    }
}

/// The pass torn in two along a jagged cut: top half lifts and rotates,
/// bottom half drops. Two masked copies of the same card.
struct SnippedPassView: View {
    let model: PassCardModel
    let snip: Bool

    var body: some View {
        ZStack {
            // Bottom half
            PassCardView(model: model, stamped: true, result: .dnf)
                .mask(alignment: .bottom) {
                    GeometryReader { geo in
                        Rectangle().frame(height: geo.size.height * 0.52)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .offset(y: snip ? 34 : 0)
                .rotationEffect(.degrees(snip ? 2 : 0), anchor: .bottom)

            // Top half
            PassCardView(model: model, stamped: true, result: .dnf)
                .mask(alignment: .top) {
                    GeometryReader { geo in
                        Rectangle().frame(height: geo.size.height * 0.48)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .offset(x: snip ? -10 : 0, y: snip ? -26 : 0)
                .rotationEffect(.degrees(snip ? -7 : 0), anchor: .bottom)
                .shadow(color: .black.opacity(snip ? 0.5 : 0), radius: 10, y: 6)
        }
        .overlay(alignment: .center) {
            if snip {
                // Torn edge highlight
                Rectangle()
                    .fill(.white.opacity(0.5))
                    .frame(height: 1.5)
                    .blur(radius: 1)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Classification (podium + timing board)

struct ClassificationView: View {
    let order: [String]
    let bestLaps: [String: TimeInterval]
    let userColorHex: String

    private func color(for code: String) -> Color {
        Color(hex: RaceSimulation.colorHex(for: code, userHex: userColorHex))
    }

    private func displayName(for code: String) -> String {
        code == "YOU" ? "YOU" : (RivalGrid.all.first { $0.code == code }?.name.uppercased() ?? code)
    }

    var body: some View {
        VStack(spacing: 16) {
            podium
            board
        }
    }

    /// P2 | P1 | P3 podium blocks; the user's column glows if they made it.
    private var podium: some View {
        let top3 = Array(order.prefix(3))
        return HStack(alignment: .bottom, spacing: 6) {
            if top3.count > 1 { podiumColumn(code: top3[1], place: 2, height: 54) }
            if !top3.isEmpty { podiumColumn(code: top3[0], place: 1, height: 76) }
            if top3.count > 2 { podiumColumn(code: top3[2], place: 3, height: 40) }
        }
        .padding(.top, 4)
    }

    private func podiumColumn(code: String, place: Int, height: CGFloat) -> some View {
        let isUser = code == "YOU"
        return VStack(spacing: 6) {
            Text(code)
                .font(.gilroy(13, isUser ? .black : .bold))
                .foregroundStyle(isUser ? color(for: code) : .white)
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isUser
                        ? color(for: code).opacity(0.85)
                        : Theme.cardHighlight
                )
                .frame(width: 84, height: height)
                .overlay(
                    Text("\(place)")
                        .font(.gilroy(26, .black))
                        .foregroundStyle(isUser ? .white : .white.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isUser ? .white.opacity(0.7) : .white.opacity(0.08),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: isUser ? color(for: code).opacity(0.6) : .clear,
                    radius: 10
                )
        }
    }

    private var board: some View {
        VStack(spacing: 0) {
            HStack {
                Text("RACE CLASSIFICATION")
                    .font(.gilroy(10, .bold))
                    .kerning(2)
                Spacer()
                Text("BEST LAP")
                    .font(.gilroy(10, .bold))
                    .kerning(2)
            }
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            ForEach(Array(order.enumerated()), id: \.element) { index, code in
                let isUser = code == "YOU"
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.gilroy(13, .black))
                        .frame(width: 22, alignment: .leading)
                        .foregroundStyle(isUser ? color(for: code) : Theme.textSecondary)
                    Rectangle()
                        .fill(color(for: code))
                        .frame(width: 3.5, height: 16)
                        .clipShape(Capsule())
                    Text(displayName(for: code))
                        .font(.gilroy(13, isUser ? .black : .semiBold))
                        .foregroundStyle(isUser ? .white : Theme.textPrimary.opacity(0.85))
                    if isUser {
                        Text("★")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.gold)
                    }
                    Spacer()
                    Text(RaceSimulation.formatLap(bestLaps[code] ?? 0))
                        .font(.gilroy(13, .medium))
                        .monospacedDigit()
                        .foregroundStyle(index == 0 ? Color(hex: "B96BFF") : Theme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isUser ? color(for: code).opacity(0.14) : (index % 2 == 0 ? Color.white.opacity(0.03) : .clear)
                )
                .overlay(
                    isUser
                        ? RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(color(for: code).opacity(0.6), lineWidth: 1)
                        : nil
                )
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

/// Waving chequered flag drawn on a Canvas — no assets needed.
struct ChequeredFlagView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Fill the whole frame with a waving checker.
                let cell = size.width / 10
                let columns = Int(ceil(size.width / cell)) + 1
                let rows = Int(ceil(size.height / cell)) + 2
                for row in 0..<rows {
                    for column in 0..<columns {
                        let wave = sin(t * 5 + Double(column) * 0.7) * 5
                        let rect = CGRect(
                            x: CGFloat(column) * cell,
                            y: CGFloat(row) * cell + wave - cell,
                            width: cell + 0.5,
                            height: cell + 0.5
                        )
                        let isBlack = (row + column) % 2 == 0
                        context.fill(
                            Path(rect),
                            with: .color(isBlack ? .black : .white)
                        )
                    }
                }
            }
        }
    }
}
