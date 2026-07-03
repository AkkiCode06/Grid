import SwiftUI

/// The data a pass card renders — buildable from a live PassDetails or a
/// stored RaceRecord (Race Log).
struct PassCardModel {
    let circuitID: String
    let circuitName: String
    let flag: String
    let country: String
    let seatName: String
    let driverName: String
    let sessionNumber: Int
    let date: Date
    let totalLaps: Int
    let durationSeconds: TimeInterval

    init(pass: PassDetails) {
        circuitID = pass.circuit.id
        circuitName = pass.circuit.name
        flag = pass.circuit.flag
        country = pass.circuit.country
        seatName = pass.seat.name
        driverName = pass.driverName
        sessionNumber = pass.sessionNumber
        date = pass.issuedAt
        totalLaps = pass.totalLaps
        durationSeconds = pass.durationSeconds
    }

    init(record: RaceRecord) {
        let circuit = CircuitLibrary.circuit(id: record.circuitID)
        circuitID = record.circuitID
        circuitName = record.circuitName
        flag = circuit?.flag ?? "🏁"
        country = circuit?.country ?? ""
        seatName = record.seatName
        driverName = record.driverName
        sessionNumber = record.sessionNumber
        date = record.startDate
        totalLaps = record.totalLaps
        durationSeconds = record.plannedSeconds
    }

    var sessionLabel: String { String(format: "SESSION %03d", sessionNumber) }
}

/// Lanyard-style paddock pass. `stamped` embosses the driver name and
/// timestamp; `result` adds the FINISHED / DNF stamp; `shimmer` runs the
/// hologram sweep once when it flips to true.
struct PassCardView: View {
    let model: PassCardModel
    var stamped: Bool = false
    var result: RaceResult? = nil
    var shimmer: Bool = false

    @State private var shimmerPhase: CGFloat = -0.6

    var body: some View {
        VStack(spacing: 0) {
            lanyardHole
            headerBand
            details
            stampArea
            BarcodeStripView(seed: model.sessionNumber &* 31 &+ model.driverName.hashValue)
                .frame(height: 44)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .overlay(resultStamp)
        .overlay(hologramSweep)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onChange(of: shimmer) { _, active in
            guard active else { return }
            shimmerPhase = -0.6
            withAnimation(.easeInOut(duration: 1.0)) {
                shimmerPhase = 1.6
            }
        }
    }

    private var lanyardHole: some View {
        Capsule()
            .fill(Theme.background)
            .frame(width: 56, height: 9)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private var headerBand: some View {
        HStack {
            Text("PADDOCK PASS")
                .font(.telemetry(12, weight: .bold))
                .kerning(3)
            Spacer()
            Text(model.sessionLabel)
                .font(.telemetry(12, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Theme.raceRed)
        .padding(.top, 6)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.circuitName)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(model.country.uppercased())
                        .font(.telemetry(10))
                        .kerning(2)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(model.flag)
                    .font(.title)
            }

            HStack(spacing: 0) {
                passField("GRANDSTAND", model.seatName.uppercased())
                passField("DATE", model.date.formatted(date: .abbreviated, time: .omitted))
                passField("TIME", model.date.formatted(date: .omitted, time: .shortened))
            }
            HStack(spacing: 0) {
                passField("DURATION", "\(Int(model.durationSeconds / 60)) MIN")
                passField("LAPS", "\(model.totalLaps)")
                passField("ACCESS", "ALL AREAS")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            TrackOutlineShape(circuitID: model.circuitID)
                .stroke(Color.white.opacity(0.05), lineWidth: 2)
                .padding(24)
        )
    }

    private func passField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.telemetry(8))
                .kerning(1.5)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Driver name area: dotted placeholder until the pass is stamped, then
    /// the name + timestamp emboss in.
    private var stampArea: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("DRIVER")
                .font(.telemetry(8))
                .kerning(1.5)
                .foregroundStyle(Theme.textTertiary)
            if stamped {
                Text(model.driverName.uppercased())
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 1.5)
                    .shadow(color: .white.opacity(0.15), radius: 0, x: 0, y: -1)
                    .transition(.scale(scale: 1.7).combined(with: .opacity))
                Text("STAMPED \(model.date.formatted(date: .numeric, time: .standard))")
                    .font(.telemetry(9))
                    .foregroundStyle(Theme.textSecondary)
                    .transition(.opacity)
            } else {
                Text("— HOLD TO STAMP —")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .animation(.spring(duration: 0.35, bounce: 0.4), value: stamped)
    }

    @ViewBuilder
    private var resultStamp: some View {
        if let result {
            Text(result.rawValue)
                .font(.system(size: 34, weight: .black))
                .kerning(4)
                .foregroundStyle(result == .finished ? Color.green : Theme.raceRed)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            result == .finished ? Color.green : Theme.raceRed,
                            lineWidth: 3
                        )
                )
                .rotationEffect(.degrees(-12))
                .opacity(0.85)
        }
    }

    private var hologramSweep: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.28), .cyan.opacity(0.18), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.45)
            .rotationEffect(.degrees(18))
            .offset(x: shimmerPhase * geo.size.width)
        }
        .allowsHitTesting(false)
    }
}

/// Deterministic fake barcode for texture — same pass always renders the
/// same bars.
struct BarcodeStripView: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white)
            )
            var state = UInt64(bitPattern: Int64(seed == 0 ? 42 : seed))
            var x: CGFloat = 6
            while x < size.width - 6 {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                let barWidth = CGFloat((state >> 33) % 3 + 1)
                let gap = CGFloat((state >> 40) % 3 + 1)
                context.fill(
                    Path(CGRect(x: x, y: 6, width: barWidth, height: size.height - 12)),
                    with: .color(.black)
                )
                x += barWidth + gap
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
