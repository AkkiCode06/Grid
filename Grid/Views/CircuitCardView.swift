import SwiftUI

struct CircuitCardView: View {
    let circuit: Circuit
    @Binding var selectedTeamID: String
    @Binding var customMinutes: Int
    let isLocked: Bool

    private var durationText: String {
        let minutes = circuit.durationMinutes ?? customMinutes
        return "\(minutes) MIN"
    }

    private var lapsText: String {
        "\(circuit.totalLaps(customMinutes: customMinutes)) LAPS"
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(circuit.flag)
                    .font(.title2)
                Text(circuit.country.uppercased())
                    .font(.telemetry(12))
                    .kerning(2)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if isLocked {
                    Label("LOCKED", systemImage: "lock.fill")
                        .font(.telemetry(10, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.gold.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.gold)
                }
            }

            TrackOutlineShape(circuitID: circuit.id)
                .stroke(
                    isLocked ? Theme.textTertiary : Theme.textPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .aspectRatio(1.4, contentMode: .fit)
                .padding(.horizontal, 12)
                .frame(maxHeight: 170)

            VStack(spacing: 6) {
                Text(circuit.name)
                    .font(.system(size: 22, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 12) {
                    Text(durationText)
                    Text("•").foregroundStyle(Theme.textTertiary)
                    Text(lapsText)
                }
                .font(.telemetry(12))
                .foregroundStyle(Theme.raceRed)
            }

            if circuit.isCustom {
                Stepper(value: $customMinutes, in: 5...240, step: 5) {
                    Text("\(customMinutes) MINUTES")
                        .font(.telemetry(13))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 8)
            }

            teamPicker
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var teamPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SIGN FOR A TEAM")
                .font(.telemetry(10))
                .kerning(2)
                .foregroundStyle(Theme.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TeamLibrary.all) { team in
                        let isSelected = team.id == selectedTeamID
                        Button {
                            Haptics.impact(.light)
                            selectedTeamID = team.id
                        } label: {
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(Color(hex: team.accentHex))
                                    .frame(width: 13, height: 13)
                                    .overlay(
                                        Circle().strokeBorder(
                                            .white.opacity(0.25), lineWidth: 1
                                        )
                                    )
                                Text(team.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                isSelected
                                    ? Color(hex: team.accentHex).opacity(0.22)
                                    : Theme.cardHighlight,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color(hex: team.accentHex) : .clear,
                                    lineWidth: 1.5
                                )
                            )
                            .foregroundStyle(
                                isSelected ? Theme.textPrimary : Theme.textSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}
