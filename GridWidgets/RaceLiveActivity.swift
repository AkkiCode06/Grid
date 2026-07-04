import ActivityKit
import WidgetKit
import SwiftUI

/// FlagSeverity itself lives in Shared/RaceActivityAttributes.swift so the
/// app and widget agree on the exact same time-based logic. This extension
/// just adds the widget-only presentation bits (icon/tint) and a
/// context-based convenience resolver.
extension FlagSeverity {
    static func resolve(_ context: ActivityViewContext<RaceActivityAttributes>) -> FlagSeverity {
        resolve(
            awayDeadline: context.state.awayDeadline,
            redDeadline: context.state.redDeadline,
            isStale: context.isStale
        )
    }

    var tint: Color {
        switch self {
        case .none: return .red        // normal race = red checkered accent
        case .warning: return .orange
        case .yellow, .red: return .yellow
        }
    }

    var icon: String {
        switch self {
        case .none: return "flag.checkered"
        case .warning: return "exclamationmark.triangle.fill"
        case .yellow, .red: return "flag.fill"
        }
    }
}

struct RaceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RaceActivityAttributes.self) { context in
            LockScreenRaceView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let severity = FlagSeverity.resolve(context)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(context.attributes.teamAssetName)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(x: -1, y: 1)
                        .frame(width: 46, height: 32)
                        .saturation(severity == .none || severity == .warning ? 1 : 0)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context, severity: severity)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context, severity: severity)
                }
            } compactLeading: {
                Image(systemName: severity.icon)
                    .foregroundStyle(severity.tint)
                    .symbolEffect(.pulse, options: .repeating, isActive: severity == .warning)
            } compactTrailing: {
                compactTrailing(context: context, severity: severity)
            } minimal: {
                Image(systemName: severity.icon)
                    .foregroundStyle(severity.tint)
            }
        }
    }

    @ViewBuilder
    private func expandedTrailing(
        context: ActivityViewContext<RaceActivityAttributes>, severity: FlagSeverity
    ) -> some View {
        switch severity {
        case .warning:
            if let deadline = context.state.awayDeadline, deadline > Date.now {
                Text(timerInterval: Date.now...deadline, countsDown: true)
                    .font(.title2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 74)
            }
        case .yellow:
            if let deadline = context.state.redDeadline, deadline > Date.now {
                Text(timerInterval: Date.now...deadline, countsDown: true)
                    .font(.title2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.yellow)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 74)
            }
        case .none, .red:
            Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                .font(.title2.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 96)
        }
    }

    @ViewBuilder
    private func expandedBottom(
        context: ActivityViewContext<RaceActivityAttributes>, severity: FlagSeverity
    ) -> some View {
        switch severity {
        case .red:
            Label("RED FLAGGED", systemImage: "flag.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(.red)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        case .yellow:
            Label("YELLOW FLAGGED", systemImage: "flag.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        case .warning:
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                Text("GET BACK TO GRID BEFORE YELLOW FLAG")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        case .none:
            HStack {
                Text(context.attributes.circuitName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("\(context.attributes.teamName.uppercased()) • LAP \(context.state.currentLap)/\(context.state.totalLaps)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func compactTrailing(
        context: ActivityViewContext<RaceActivityAttributes>, severity: FlagSeverity
    ) -> some View {
        switch severity {
        case .warning:
            if let deadline = context.state.awayDeadline, deadline > Date.now {
                Text(timerInterval: Date.now...deadline, countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.orange)
                    .frame(maxWidth: 44)
                    .multilineTextAlignment(.trailing)
            }
        case .yellow:
            Text("FLAG")
                .font(.system(size: 10).weight(.black))
                .foregroundStyle(.yellow)
                .lineLimit(1)
                .fixedSize()
        case .red:
            Text("RED")
                .font(.system(size: 10).weight(.black))
                .foregroundStyle(.red)
                .lineLimit(1)
                .fixedSize()
        case .none:
            Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                .font(.caption2.monospacedDigit())
                .frame(maxWidth: 44)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct LockScreenRaceView: View {
    let context: ActivityViewContext<RaceActivityAttributes>

    private var severity: FlagSeverity { FlagSeverity.resolve(context) }

    var body: some View {
        HStack(spacing: 14) {
            // Team car — front faces right, toward the message.
            Image(context.attributes.teamAssetName)
                .resizable()
                .scaledToFit()
                .scaleEffect(x: -1, y: 1) // flip so the nose points right
                .frame(width: 58, height: 40)
                .saturation(severity == .none || severity == .warning ? 1 : 0)
                .opacity(severity == .none ? 1 : 0.9)

            // Middle message
            HStack(spacing: 8) {
                if severity != .none {
                    Image(systemName: severity.icon)
                        .font(.title3)
                        .foregroundStyle(severity.tint)
                        .symbolEffect(.pulse, options: .repeating, isActive: severity == .warning)
                }
                VStack(alignment: .leading, spacing: 2) {
                    switch severity {
                    case .red:
                        Text("RED FLAGGED")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("session at risk — get back now")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    case .yellow:
                        Text("YELLOW FLAGGED")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.yellow)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    case .warning:
                        Text("GET BACK TO GRID")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("before you're yellow flagged")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    case .none:
                        Text(context.attributes.circuitName)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                        Text("\(context.attributes.teamName.uppercased()) • LAP \(context.state.currentLap)/\(context.state.totalLaps)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            // Right — countdown to the next escalation, or the session
            // timer once green or fully red.
            Group {
                if severity == .warning, let deadline = context.state.awayDeadline, deadline > Date.now {
                    countdown(to: deadline, label: "TO FLAG", color: .orange)
                } else if severity == .yellow, let deadline = context.state.redDeadline, deadline > Date.now {
                    countdown(to: deadline, label: "TO RED", color: .yellow)
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

    private func countdown(to deadline: Date, label: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(timerInterval: Date.now...deadline, countsDown: true)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(maxWidth: 66, alignment: .trailing)
            Text(label)
                .font(.system(size: 8).weight(.bold))
                .foregroundStyle(.secondary)
        }
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
