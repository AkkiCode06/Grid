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
                let flag = resolvedFlag(context)
                Image(systemName: flag != nil ? "flag.fill" : "flag.checkered")
                    .foregroundStyle(flag == .red ? .red : flag == .yellow ? .yellow : .red)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.endDate,
                     countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(maxWidth: 44)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                let flag = resolvedFlag(context)
                Image(systemName: flag != nil ? "flag.fill" : "flag.checkered")
                    .foregroundStyle(flag == .red ? .red : flag == .yellow ? .yellow : .red)
            }
        }
    }

    /// Determine the effective flag state, escalating yellow → red when stale.
    private func resolvedFlag(_ context: ActivityViewContext<RaceActivityAttributes>) -> FlagState? {
        if context.state.flagRaw == "red" { return .red }
        if context.state.flagRaw == "yellow" {
            return context.isStale ? .red : .yellow
        }
        return nil
    }
}

private enum FlagState {
    case yellow, red
}

private struct LockScreenRaceView: View {
    let context: ActivityViewContext<RaceActivityAttributes>

    private var flag: FlagState? {
        if context.state.flagRaw == "red" { return .red }
        if context.state.flagRaw == "yellow" {
            return context.isStale ? .red : .yellow
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let flag {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                    Text(flag == .red
                         ? "RED FLAG — GET BACK TO GRID NOW"
                         : "YELLOW FLAG — BACK TO THE PITS")
                        .font(.caption2.weight(.black))
                        .kerning(1)
                }
                .foregroundStyle(flag == .red ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(flag == .red ? Color.red : Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(flag == .red ? .red : flag == .yellow ? .yellow : .red)
                Text(context.attributes.circuitName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(String(format: "SESSION %03d", context.attributes.sessionNumber))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("LAP \(context.state.currentLap)/\(context.state.totalLaps)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text(timerInterval: context.state.startDate...context.state.endDate,
                     countsDown: true)
                    .font(.headline.weight(.bold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            ProgressView(timerInterval: context.state.startDate...context.state.endDate,
                         countsDown: false, label: { EmptyView() },
                         currentValueLabel: { EmptyView() })
                .progressViewStyle(.linear)
                .tint(.red)
        }
        .padding(14)
        .foregroundStyle(.white)
    }
}

