import SwiftUI
import SwiftData

/// The retention hook: a scrollable collection of every stamped pass,
/// finished and DNF alike.
struct RaceLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RaceRecord.startDate, order: .reverse) private var records: [RaceRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "flag.checkered",
                        description: Text("Stamp your first paddock pass to start your Race Log.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(records) { record in
                                RaceLogRow(record: record)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Race Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct RaceLogRow: View {
    let record: RaceRecord

    private var circuit: Circuit? {
        CircuitLibrary.circuit(id: record.circuitID)
    }

    var body: some View {
        HStack(spacing: 14) {
            TrackOutlineShape(circuitID: record.circuitID)
                .stroke(Theme.textSecondary, lineWidth: 2)
                .aspectRatio(1.4, contentMode: .fit)
                .frame(width: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.circuitName)
                    .font(.gilroy(15, .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(circuit?.flag ?? "🏁") \(record.teamName.uppercased()) • \(String(format: "SESSION %03d", record.sessionNumber))")
                    .font(.telemetry(9))
                    .kerning(1)
                    .foregroundStyle(Theme.textSecondary)
                Text("\(record.startDate.formatted(date: .abbreviated, time: .shortened)) • \(record.completedLaps)/\(record.totalLaps) LAPS")
                    .font(.telemetry(9))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Text(record.result.rawValue)
                .font(.telemetry(10, weight: .black))
                .kerning(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            record.result == .finished ? Color.green : Theme.raceRed,
                            lineWidth: 1.5
                        )
                )
                .foregroundStyle(record.result == .finished ? Color.green : Theme.raceRed)
                .rotationEffect(.degrees(-6))
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
