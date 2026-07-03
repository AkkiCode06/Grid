import SwiftUI

struct CircuitCardView: View {
    let circuit: Circuit
    @Binding var selectedSeatID: String
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

            seatPicker
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var seatPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GRANDSTAND")
                .font(.telemetry(10))
                .kerning(2)
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 8) {
                ForEach(circuit.seats) { seat in
                    let isSelected = seat.id == selectedSeatID
                    Button {
                        Haptics.impact(.light)
                        selectedSeatID = seat.id
                    } label: {
                        Text(seat.name)
                            .font(.system(size: 11, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? Theme.raceRed.opacity(0.25) : Theme.cardHighlight,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        isSelected ? Theme.raceRed : .clear,
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
