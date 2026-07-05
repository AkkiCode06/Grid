import SwiftUI
import SwiftData

/// Advanced focus tracking: a last-session focus score, a GitHub-style
/// contribution heatmap of days on Grid, headline stats, where you struggled,
/// and the trophies you've stamped. Computed from the Race Log so it's always
/// in sync with real history.
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
                    focusHero
                    heatmapCard
                    headlineGrid
                    struggleCard
                    trophyCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Focus hero (last session)

    private var focusHero: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(stats.lastFocusScore) / 100)
                    .stroke(
                        AngularGradient(colors: [Theme.raceRed, .orange, Theme.raceRed],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(stats.lastFocusScore)")
                        .font(.gilroy(30, .heavy))
                        .foregroundStyle(.white)
                    Text("FOCUS")
                        .font(.gilroy(9, .bold)).kerning(1.5)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text("LAST SESSION")
                    .font(.gilroy(10, .bold)).kerning(1.5)
                    .foregroundStyle(Theme.textTertiary)
                Text(stats.lastSessionVerdict)
                    .font(.gilroy(18, .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(stats.lastSessionDetail)
                    .font(.gilroy(12, .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DAYS ON GRID")
                    .font(.gilroy(11, .bold)).kerning(2)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(stats.activeDayCount) days")
                    .font(.gilroy(11, .bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            ContributionHeatmap(minutesByDay: stats.minutesByDay)
            HStack(spacing: 6) {
                Text("Less").font(.gilroy(9, .medium)).foregroundStyle(Theme.textTertiary)
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ContributionHeatmap.color(for: level))
                        .frame(width: 11, height: 11)
                }
                Text("More").font(.gilroy(9, .medium)).foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Headline cards

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "clock.fill", value: stats.totalTimeLabel,
                     label: "TIME LOCKED IN", tint: Theme.raceRed)
            StatCard(icon: "flame.fill", value: "\(stats.currentStreak)",
                     label: "DAY STREAK", tint: .orange)
            StatCard(icon: "checkmark.seal.fill", value: "\(stats.completionRate)%",
                     label: "FINISH RATE", tint: .green)
            StatCard(icon: "hand.raised.fill", value: "\(stats.totalFlags)",
                     label: "TIMES PULLED AWAY", tint: .yellow)
        }
    }

    // MARK: - Where you struggled

    @ViewBuilder
    private var struggleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WHAT PULLED YOU BACK")
                .font(.gilroy(11, .bold)).kerning(2)
                .foregroundStyle(Theme.textTertiary)

            if stats.totalFlags == 0 {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("Ice cold — you never broke away. Keep it clean.")
                        .font(.gilroy(13, .semiBold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            } else {
                ForEach(stats.struggles) { s in
                    HStack(spacing: 12) {
                        Text(s.flag).font(.title3)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.name)
                                .font(.gilroy(14, .bold))
                                .foregroundStyle(.white)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.08))
                                    Capsule().fill(Theme.raceRed)
                                        .frame(width: geo.size.width * s.fraction)
                                }
                            }
                            .frame(height: 6)
                        }
                        Text("\(s.flags)")
                            .font(.gilroy(15, .heavy))
                            .foregroundStyle(Theme.raceRed)
                    }
                }
                Text("Breakaways per circuit — where focus slipped most.")
                    .font(.gilroy(11, .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Trophies

    private var trophyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("TROPHY CABINET")
                    .font(.gilroy(11, .bold)).kerning(2)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(stats.earnedTrophies)/\(Achievements.all.count)")
                    .font(.gilroy(11, .bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                ForEach(Achievements.all) { trophy in
                    let earned = trophy.isEarned(finishedSessions: stats.finishedCount)
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(earned ? Theme.gold.opacity(0.16) : Color.white.opacity(0.05))
                                .frame(width: 46, height: 46)
                            Image(systemName: earned ? trophy.icon : "lock.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(earned ? Theme.gold : Theme.textTertiary)
                        }
                        Text(earned ? trophy.name : "\(trophy.sessions)")
                            .font(.gilroy(9, .bold))
                            .foregroundStyle(earned ? .white.opacity(0.85) : Theme.textTertiary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
            }
            if let next = Achievements.next(finishedSessions: stats.finishedCount) {
                Text("Next: \(next.name) at \(next.sessions) sessions — \(next.sessions - stats.finishedCount) to go.")
                    .font(.gilroy(11, .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Contribution heatmap

struct ContributionHeatmap: View {
    /// Minutes focused, keyed by start-of-day.
    let minutesByDay: [Date: Double]
    var weeks: Int = 16

    private let cell: CGFloat = 13
    private let gap: CGFloat = 3

    static func color(for level: Int) -> Color {
        switch level {
        case 1: return Theme.raceRed.opacity(0.30)
        case 2: return Theme.raceRed.opacity(0.55)
        case 3: return Theme.raceRed.opacity(0.78)
        case 4: return Theme.raceRed
        default: return Color.white.opacity(0.06)
        }
    }

    private func level(_ minutes: Double) -> Int {
        switch minutes {
        case ..<0.5: return 0
        case ..<20: return 1
        case ..<45: return 2
        case ..<90: return 3
        default: return 4
        }
    }

    /// Column-major grid of day-start dates; nil pads the final week.
    private var columns: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        // End on the current week's Saturday so today sits in the last column.
        let weekdayIdx = cal.component(.weekday, from: today) - 1 // 0 = Sunday
        guard let lastSunday = cal.date(byAdding: .day, value: -weekdayIdx, to: today),
              let firstSunday = cal.date(byAdding: .day, value: -7 * (weeks - 1), to: lastSunday)
        else { return [] }

        var cols: [[Date?]] = []
        for w in 0..<weeks {
            var col: [Date?] = []
            for d in 0..<7 {
                if let day = cal.date(byAdding: .day, value: w * 7 + d, to: firstSunday),
                   day <= today {
                    col.append(day)
                } else {
                    col.append(nil)
                }
            }
            cols.append(col)
        }
        return cols
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: gap) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { idx, col in
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                if let day = col[row] {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Self.color(for: level(minutesByDay[day] ?? 0)))
                                        .frame(width: cell, height: cell)
                                } else {
                                    Color.clear.frame(width: cell, height: cell)
                                }
                            }
                        }
                        .id(idx)
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear { proxy.scrollTo(columns.count - 1, anchor: .trailing) }
        }
    }
}

// MARK: - Stats computation

private struct RaceStats {
    let totalTimeLabel: String
    let currentStreak: Int
    let completionRate: Int
    let totalFlags: Int
    let finishedCount: Int
    let earnedTrophies: Int
    let activeDayCount: Int
    let minutesByDay: [Date: Double]
    let lastFocusScore: Int
    let lastSessionVerdict: String
    let lastSessionDetail: String
    let struggles: [Struggle]

    struct Struggle: Identifiable {
        let name: String
        let flag: String
        let flags: Int
        let fraction: Double
        var id: String { name }
    }

    init(records: [RaceRecord]) {
        let cal = Calendar.current

        let totalSeconds = records.reduce(0) { $0 + $1.completedSeconds }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        totalTimeLabel = hours > 0 ? "\(hours)H \(minutes)M" : "\(minutes)M"

        let finished = records.filter { $0.result == .finished }
        finishedCount = finished.count
        completionRate = records.isEmpty ? 0 : Int((Double(finished.count) / Double(records.count) * 100).rounded())
        totalFlags = records.reduce(0) { $0 + $1.flagCount }
        earnedTrophies = Achievements.earnedCount(finishedSessions: finished.count)

        // Minutes per day + active-day count.
        var byDay: [Date: Double] = [:]
        for r in records {
            let day = cal.startOfDay(for: r.startDate)
            byDay[day, default: 0] += r.completedSeconds / 60
        }
        minutesByDay = byDay
        activeDayCount = byDay.keys.count

        // Streak: consecutive days back from today with a finished session.
        let finishedDays = Set(finished.map { cal.startOfDay(for: $0.startDate) })
        var streak = 0
        var cursor = cal.startOfDay(for: .now)
        while finishedDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        currentStreak = streak

        // Last session focus score: lap completion, penalised by breakaways.
        if let last = records.max(by: { $0.startDate < $1.startDate }) {
            let completion = Double(last.completedLaps) / Double(max(1, last.totalLaps))
            let raw = completion * 100 - Double(last.flagCount) * 8
            let score = max(0, min(100, Int(raw.rounded())))
            lastFocusScore = score
            switch score {
            case 90...100: lastSessionVerdict = "Locked in."
            case 70..<90:  lastSessionVerdict = "Strong drive."
            case 40..<70:  lastSessionVerdict = "Held on."
            default:       lastSessionVerdict = "Rough stint."
            }
            let flagsPart = last.flagCount == 0 ? "no breakaways" :
                "\(last.flagCount) breakaway\(last.flagCount == 1 ? "" : "s")"
            lastSessionDetail = "\(last.completedLaps)/\(last.totalLaps) laps · \(flagsPart)"
        } else {
            lastFocusScore = 0
            lastSessionVerdict = "No sessions yet."
            lastSessionDetail = ""
        }

        // Where you struggled: breakaways grouped by circuit.
        let flaggedRecords = records.filter { $0.flagCount > 0 }
        let grouped = Dictionary(grouping: flaggedRecords, by: { $0.circuitName })
        let maxFlags = grouped.values.map { $0.reduce(0) { $0 + $1.flagCount } }.max() ?? 1
        struggles = grouped
            .map { name, recs -> Struggle in
                let flags = recs.reduce(0) { $0 + $1.flagCount }
                let flag = CircuitLibrary.circuit(id: recs.first?.circuitID ?? "")?.flag ?? "🏁"
                return Struggle(name: name, flag: flag, flags: flags,
                                fraction: Double(flags) / Double(max(1, maxFlags)))
            }
            .sorted { $0.flags > $1.flags }
            .prefix(3)
            .map { $0 }
    }
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
