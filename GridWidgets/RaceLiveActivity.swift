import ActivityKit
import WidgetKit
import SwiftUI

struct RaceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RaceActivityAttributes.self) { context in
            LockScreenRaceView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.circuitName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(context.attributes.teamName.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: context.state.startDate...context.state.endDate,
                             countsDown: true)
                            .font(.title3.weight(.bold).monospacedDigit())
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 70)
                        Text("LAP \(context.state.currentLap)/\(context.state.totalLaps)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: context.state.startDate...context.state.endDate,
                                 countsDown: false, label: { EmptyView() },
                                 currentValueLabel: { EmptyView() })
                        .progressViewStyle(.linear)
                        .tint(.red)
                }
            } compactLeading: {
                let away = context.state.awayDeadline != nil
                Image(systemName: away ? "flag.fill" : "flag.checkered")
                    .foregroundStyle(away ? .yellow : .red)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.endDate,
                     countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(maxWidth: 44)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                let away = context.state.awayDeadline != nil
                Image(systemName: away ? "flag.fill" : "flag.checkered")
                    .foregroundStyle(away ? .yellow : .red)
            }
        }
    }
}

private struct LockScreenRaceView: View {
    let context: ActivityViewContext<RaceActivityAttributes>

    private var teamColor: Color { Color(hex: context.attributes.teamColorHex) }

    /// Away = user left the app. Flagged = away long enough that the grace
    /// window elapsed (the activity went stale at the deadline).
    private var isAway: Bool { context.state.awayDeadline != nil }
    private var isFlagged: Bool { isAway && context.isStale }

    var body: some View {
        HStack(spacing: 14) {
            // Car — front faces right, toward the message.
            Image(systemName: "car.side.fill")
                .font(.system(size: 34))
                .scaleEffect(x: -1, y: 1) // flip so the nose points right
                .foregroundStyle(isFlagged ? .yellow : teamColor)
                .shadow(color: (isFlagged ? Color.yellow : teamColor).opacity(0.6), radius: 4)
                .frame(width: 52)

            // Middle message
            VStack(alignment: .leading, spacing: 3) {
                if isFlagged {
                    Text("YELLOW FLAGGED")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.yellow)
                    Text(context.attributes.circuitName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if isAway {
                    Text("Get back to Grid")
                        .font(.subheadline.weight(.bold))
                    Text("before you're yellow flagged")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(context.attributes.circuitName)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    Text("\(context.attributes.teamName.uppercased()) • LAP \(context.state.currentLap)/\(context.state.totalLaps)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            // Right — grace countdown while away (not yet flagged),
            // otherwise the session time remaining.
            Group {
                if isAway && !isFlagged, let deadline = context.state.awayDeadline {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timerInterval: Date.now...deadline, countsDown: true)
                            .font(.system(.title, design: .rounded).weight(.heavy))
                            .monospacedDigit()
                            .foregroundStyle(.yellow)
                            .frame(maxWidth: 66, alignment: .trailing)
                        Text("TO FLAG")
                            .font(.system(size: 8).weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(timerInterval: context.state.startDate...context.state.endDate,
                         countsDown: true)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(maxWidth: 100, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
    }
}


// Local hex initialiser — the widget target doesn't compile Theme.swift.
extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
