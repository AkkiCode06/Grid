import SwiftUI
import Charts
import SwiftData

/// "How well are you staying locked in" — the Opal-style stats screen.
/// Headline cards (time locked in, streak, completion rate, distractions
/// caught) plus a weekly bar chart of focus minutes, computed from the Race
/// Log so it's always in sync with real session history.
struct StatsView: View {
    let records: [RaceRecord]

    private var stats: RaceStats { RaceStats(records: records) }

    var body: some View {
        if records.isEmpty {
            ContentUnavailableView(
                "No stats yet",
                systemImage: "chart.bar.fill",
                description: Text("Finish your first session to start tracking your focus.")
            )
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    headlineGrid
                    weeklyChart
                    breakdownRow
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "clock.fill",
                value: stats.totalTimeLabel,
                label: "TIME LOCKED IN",
                tint: Theme.raceRed
            )
            StatCard(
                icon: "flame.fill",
                value: "\(stats.currentStreak)",
                label: "DAY STREAK",
                tint: .orange
            )
            StatCard(
                icon: "checkmark.seal.fill",
                value: "\(stats.completionRate)%",
                label: "FINISH RATE",
                tint: .green
            )
            StatCard(
                icon: "flag.fill",
                value: "\(stats.totalFlags)",
                label: "TIMES FLAGGED",
                tint: .yellow
            )
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LAST 7 DAYS")
                .font(.gilroy(11, .bold))
                .kerning(2)
                .foregroundStyle(Theme.textTertiary)

            Chart(stats.dailyMinutes) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(day.minutes > 0 ? Theme.raceRed : Theme.cardHighlight)
                .cornerRadius(4)
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(Theme.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var breakdownRow: some View {
        if stats.favoriteCircuit != nil || stats.favoriteTeam != nil {
            HStack(spacing: 12) {
                if let circuit = stats.favoriteCircuit {
                    BreakdownPill(icon: "flag.checkered", title: "FAVOURITE CIRCUIT", value: circuit)
                }
                if let team = stats.favoriteTeam {
                    BreakdownPill(icon: "person.2.fill", title: "MOST RACED FOR", value: team)
                }
            }
        }
    }
}

// MARK: - Stats computation

private struct RaceStats {
    let totalTimeLabel: String
    let currentStreak: Int
    let completionRate: Int
    let totalFlags: Int
    let dailyMinutes: [DayMinutes]
    let favoriteCircuit: String?
    let favoriteTeam: String?

    init(records: [RaceRecord]) {
        let totalSeconds = records.reduce(0) { $0 + $1.completedSeconds }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        totalTimeLabel = hours > 0 ? "\(hours)H \(minutes)M" : "\(minutes)M"

        let finishedCount = records.filter { $0.result == .finished }.count
        completionRate = records.isEmpty ? 0 : Int((Double(finishedCount) / Double(records.count) * 100).rounded())
        totalFlags = records.reduce(0) { $0 + $1.flagCount }

        // Streak: consecutive days (walking back from today) with at least
        // one finished session.
        let calendar = Calendar.current
        let finishedDays = Set(
            records.filter { $0.result == .finished }.map { calendar.startOfDay(for: $0.startDate) }
        )
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        while finishedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        currentStreak = streak

        // Last 7 days, oldest to newest, minutes locked in per day.
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        var days: [DayMinutes] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) else { continue }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let seconds = records
                .filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
                .reduce(0) { $0 + $1.completedSeconds }
            days.append(DayMinutes(label: formatter.string(from: dayStart), minutes: seconds / 60))
        }
        dailyMinutes = days

        func mode(of values: [String]) -> String? {
            guard !values.isEmpty else { return nil }
            let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
            return counts.max(by: { $0.value < $1.value })?.key
        }
        favoriteCircuit = mode(of: records.map(\.circuitName))
        favoriteTeam = mode(of: records.map(\.teamName))
    }
}

private struct DayMinutes: Identifiable {
    let label: String
    let minutes: Double
    var id: String { label + String(minutes) }
}

// MARK: - Small views

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.gilroy(24, .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.gilroy(10, .bold))
                .kerning(1.2)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct BreakdownPill: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.gilroy(9, .bold))
                .kerning(1)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.gilroy(14, .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
