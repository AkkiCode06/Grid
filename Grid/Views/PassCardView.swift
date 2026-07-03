import SwiftUI

/// The data a pass card renders — buildable from a live PassDetails or a
/// stored RaceRecord (Race Log).
struct PassCardModel {
    let circuitID: String
    let circuitName: String
    let flag: String
    let country: String
    let teamName: String
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
        teamName = pass.team.name
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
        teamName = record.teamName
        driverName = record.driverName
        sessionNumber = record.sessionNumber
        date = record.startDate
        totalLaps = record.totalLaps
        durationSeconds = record.plannedSeconds
    }

    var sessionLabel: String { String(format: "SESSION %03d", sessionNumber) }
}

/// Lanyard-style paddock pass, modelled on real race-weekend VIP passes:
/// coloured card, hazard stripe bands, giant block role print with a script
/// flourish, vertical year. Colours and wording come from the user's
/// PassTheme. `stamped` embosses the driver name; `result` adds the
/// FINISHED / DNF stamp; `shimmer` runs the hologram sweep once.
struct PassCardView: View {
    let model: PassCardModel
    var stamped: Bool = false
    var result: RaceResult? = nil
    var shimmer: Bool = false
    /// Set for live previews (Pass Studio); defaults to the saved theme.
    var themeOverride: PassTheme? = nil

    @State private var shimmerPhase: CGFloat = -0.6

    private var theme: PassTheme { themeOverride ?? PassThemeStore.shared.theme }

    var body: some View {
        GeometryReader { geo in
            card(width: geo.size.width)
        }
        .aspectRatio(0.72, contentMode: .fit)
    }

    private func card(width w: CGFloat) -> some View {
        VStack(spacing: 0) {
            StripeBand(color: theme.ink)
                .frame(height: w * 0.05)

            header(w)
                .padding(.horizontal, w * 0.06)
                .padding(.top, w * 0.05)

            Spacer(minLength: 0)

            roleBlock(w)

            Spacer(minLength: 0)

            detailsStrip(w)

            driverArea(w)
                .padding(.horizontal, w * 0.06)
                .padding(.vertical, w * 0.035)

            bottomRow(w)
                .padding(.horizontal, w * 0.06)
                .padding(.bottom, w * 0.04)

            if theme.showBarcode {
                BarcodeStripView(seed: model.sessionNumber &* 31 &+ model.driverName.hashValue)
                    .frame(height: w * 0.11)
                    .padding(.horizontal, w * 0.06)
                    .padding(.bottom, w * 0.05)
            }

            StripeBand(color: theme.ink)
                .frame(height: w * 0.05)
        }
        .background(theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: w * 0.055))
        .overlay(
            RoundedRectangle(cornerRadius: w * 0.055)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .overlay(resultStamp(w))
        .overlay(hologramSweep)
        .clipShape(RoundedRectangle(cornerRadius: w * 0.055))
        .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
        .onChange(of: shimmer) { _, active in
            guard active else { return }
            shimmerPhase = -0.6
            withAnimation(.easeInOut(duration: 1.0)) {
                shimmerPhase = 1.6
            }
        }
    }

    // MARK: - Pieces

    private func header(_ w: CGFloat) -> some View {
        HStack(alignment: .top) {
            Text("GRID")
                .font(.system(size: w * 0.08, weight: .black))
                .italic()
                .foregroundStyle(theme.accent)
                .padding(.horizontal, w * 0.045)
                .padding(.vertical, w * 0.018)
                .background(theme.ink)
                .clipShape(SlantedRect(skew: 0.22))

            Spacer()

            verticalYear(w)
        }
    }

    /// Year printed as stacked pairs of digits ("2026" → "20" over "26").
    private func verticalYear(_ w: CGFloat) -> some View {
        let digits = Array(theme.yearText)
        let rows: [String] = stride(from: 0, to: digits.count, by: 2).map {
            String(digits[$0..<min($0 + 2, digits.count)])
        }
        return VStack(alignment: .trailing, spacing: -w * 0.012) {
            ForEach(rows, id: \.self) { row in
                Text(row)
                    .font(.system(size: w * 0.085, weight: .black))
                    .fontWidth(.condensed)
            }
        }
        .foregroundStyle(theme.ink)
    }

    private func roleBlock(_ w: CGFloat) -> some View {
        ZStack {
            Text(theme.roleText.uppercased())
                .font(.system(size: w * 0.34, weight: .black))
                .fontWidth(.condensed)
                .kerning(-w * 0.008)
                .lineLimit(1)
                .minimumScaleFactor(0.25)
                .foregroundStyle(theme.ink)
                .padding(.horizontal, w * 0.05)

            if !theme.scriptText.isEmpty {
                Text(theme.scriptText)
                    .font(.custom("SnellRoundhand-Bold", size: w * 0.17))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(theme.foil)
                    .rotationEffect(.degrees(-7))
                    .offset(x: w * 0.05, y: w * 0.115)
                    .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
            }
        }
    }

    private func detailsStrip(_ w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: w * 0.012) {
            HStack(spacing: w * 0.02) {
                Text(model.flag)
                    .font(.system(size: w * 0.05))
                Text(model.circuitName.uppercased())
                    .font(.system(size: w * 0.042, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                if theme.showSessionNumber {
                    Text(model.sessionLabel)
                        .font(.system(size: w * 0.038, weight: .bold, design: .monospaced))
                }
            }
            HStack(spacing: w * 0.015) {
                Text(model.teamName.uppercased())
                if let dateText = theme.dateStyle.text(for: model.date) {
                    Text("•")
                    Text(dateText.uppercased())
                }
                Text("•")
                Text("\(Int(model.durationSeconds / 60)) MIN / \(model.totalLaps) LAPS")
                Spacer()
            }
            .font(.system(size: w * 0.033, weight: .semibold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.45)
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, w * 0.06)
        .padding(.vertical, w * 0.035)
        .frame(maxWidth: .infinity)
        .background(theme.ink)
    }

    private func driverArea(_ w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: w * 0.008) {
            Text("DRIVER")
                .font(.system(size: w * 0.028, weight: .bold, design: .monospaced))
                .kerning(2)
                .foregroundStyle(theme.ink.opacity(0.55))
            if stamped {
                Text(model.driverName.uppercased())
                    .font(.system(size: w * 0.085, weight: .black))
                    .fontWidth(.condensed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(theme.ink)
                    .shadow(color: .black.opacity(0.35), radius: 0, y: 1)
                    .shadow(color: .white.opacity(0.25), radius: 0, y: -1)
                    .transition(.scale(scale: 1.7).combined(with: .opacity))
                if let dateText = PassDateStyle.dateAndTime.text(for: model.date) {
                    Text("STAMPED \(dateText.uppercased())")
                        .font(.system(size: w * 0.026, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.ink.opacity(0.6))
                        .transition(.opacity)
                }
            } else {
                Text("— HOLD TO STAMP —")
                    .font(.system(size: w * 0.085, weight: .black))
                    .fontWidth(.condensed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(theme.ink.opacity(0.25))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(duration: 0.35, bounce: 0.4), value: stamped)
    }

    private func bottomRow(_ w: CGFloat) -> some View {
        HStack(spacing: w * 0.04) {
            if theme.showTrackOutline {
                TrackOutlineShape(circuitID: model.circuitID)
                    .stroke(theme.ink, lineWidth: w * 0.008)
                    .frame(width: w * 0.16, height: w * 0.12)
            }
            Text(theme.eventText.uppercased())
                .font(.system(size: w * 0.03, weight: .bold))
                .kerning(1.5)
                .lineLimit(2)
                .foregroundStyle(theme.ink.opacity(0.75))
            Spacer()
        }
    }

    @ViewBuilder
    private func resultStamp(_ w: CGFloat) -> some View {
        if let result {
            Text(result.rawValue)
                .font(.system(size: w * 0.11, weight: .black))
                .kerning(4)
                .foregroundStyle(result == .finished ? Color.green : Color(hex: "E10A17"))
                .padding(.horizontal, w * 0.045)
                .padding(.vertical, w * 0.02)
                .overlay(
                    RoundedRectangle(cornerRadius: w * 0.025)
                        .strokeBorder(
                            result == .finished ? Color.green : Color(hex: "E10A17"),
                            lineWidth: w * 0.01
                        )
                )
                .rotationEffect(.degrees(-12))
                .opacity(0.9)
        }
    }

    private var hologramSweep: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.32), .cyan.opacity(0.2), .clear],
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

/// Diagonal hazard stripes used for the pass's top and bottom bands.
struct StripeBand: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let stripe = size.height * 1.1
            var x = -size.height * 2
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + stripe, y: size.height))
                path.addLine(to: CGPoint(x: x + stripe + size.height, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(color))
                x += stripe * 2
            }
        }
    }
}

/// Parallelogram clip for the wordmark chip.
struct SlantedRect: Shape {
    /// Horizontal skew as a fraction of height.
    let skew: CGFloat

    func path(in rect: CGRect) -> Path {
        let offset = rect.height * skew
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - offset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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
                    Path(CGRect(x: x, y: 5, width: barWidth, height: size.height - 10)),
                    with: .color(.black)
                )
                x += barWidth + gap
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
