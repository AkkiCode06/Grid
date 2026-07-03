import SwiftUI

/// Session end: chequered flag for a finish, a quieter DNF treatment for an
/// early exit. Either way the pass is stamped and already in the Race Log.
struct FinishView: View {
    let pass: PassDetails
    let startDate: Date
    let result: RaceResult

    @Environment(SessionController.self) private var session

    private var completedMinutes: Int {
        let completed = min(pass.durationSeconds, Date.now.timeIntervalSince(startDate))
        return max(0, Int(completed / 60))
    }

    var body: some View {
        VStack(spacing: 20) {
            if result == .finished {
                ChequeredFlagView()
                    .frame(height: 110)
                    .padding(.top, 24)
                Text("CHEQUERED FLAG")
                    .font(.telemetry(16, weight: .black))
                    .kerning(4)
                    .foregroundStyle(Theme.gold)
            } else {
                Image(systemName: "flag.slash.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.raceRed)
                    .padding(.top, 48)
                Text("DID NOT FINISH")
                    .font(.telemetry(16, weight: .black))
                    .kerning(4)
                    .foregroundStyle(Theme.raceRed)
            }

            PassCardView(
                model: PassCardModel(pass: pass),
                stamped: true,
                result: result
            )
            .padding(.horizontal, 32)

            Text(
                result == .finished
                    ? "\(pass.totalLaps) LAPS • \(completedMinutes) MIN LOCKED IN"
                    : "RETIRED AFTER \(completedMinutes) MIN"
            )
            .font(.telemetry(11))
            .kerning(2)
            .foregroundStyle(Theme.textSecondary)

            Spacer()

            Button {
                session.dismissEnded()
            } label: {
                Text("RETURN TO PADDOCK")
                    .font(.telemetry(14, weight: .bold))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.cardHighlight, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
    }
}

/// Waving chequered flag drawn on a Canvas — no assets needed.
struct ChequeredFlagView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let columns = 10
                let rows = 5
                let cell = size.width / CGFloat(columns)
                let flagHeight = cell * CGFloat(rows)
                let yOffset = (size.height - flagHeight) / 2
                for row in 0..<rows {
                    for column in 0..<columns {
                        let wave = sin(t * 5 + Double(column) * 0.7) * 5
                        let rect = CGRect(
                            x: CGFloat(column) * cell,
                            y: yOffset + CGFloat(row) * cell + wave,
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
