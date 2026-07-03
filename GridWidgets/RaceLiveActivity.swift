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
                        Text(context.attributes.seatName.uppercased())
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
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.endDate,
                     countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(maxWidth: 44)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct LockScreenRaceView: View {
    let context: ActivityViewContext<RaceActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.red)
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
