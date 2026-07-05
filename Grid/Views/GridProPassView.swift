import SwiftUI

/// The membership card issued when you go Pro — distinct from the team
/// paddock pass. Red & black, premium, gyro-reactive 3D tilt, with the
/// driver's real signature, a barcode, and a radial holographic sticker in
/// the bottom-right corner.
struct GridProPassView: View {
    let driverName: String
    var memberNumber: Int = 1
    /// When true, the signature writes itself in on appear.
    var animateSignature: Bool = false
    /// Finished sessions — drives which trophy stamps show on the back.
    var finishedSessions: Int = 0

    @State private var sigProgress: CGFloat = 1
    @State private var flipped = false

    private var joinedLabel: String {
        Date.now.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    }

    var body: some View {
        GeometryReader { geo in
            let tilt = MotionTilt.shared
            let w = geo.size.width
            ZStack {
                cardFront(width: w)
                    .opacity(flipped ? 0 : 1)
                cardBack(width: w)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(flipped ? 1 : 0)
            }
            .rotation3DEffect(.degrees(flipped ? 180 : 0),
                              axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(tilt.roll * 14),
                              axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(-tilt.pitch * 11),
                              axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.impact(.rigid)
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                    flipped.toggle()
                }
            }
        }
        .aspectRatio(0.63, contentMode: .fit)
        .onAppear {
            if animateSignature {
                sigProgress = 0
                SoundPlayer.shared.play("signature")
                withAnimation(.easeOut(duration: 1.6).delay(0.6)) { sigProgress = 1 }
                for i in 0..<7 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.2) {
                        Haptics.impact(.light)
                    }
                }
            }
        }
    }

    private func cardFront(width w: CGFloat) -> some View {
        ZStack {
            // Black base with a red glow bleeding up from the bottom.
            RoundedRectangle(cornerRadius: w * 0.07)
                .fill(Color(white: 0.05))
                .overlay(
                    RadialGradient(
                        colors: [Theme.raceRed.opacity(0.55), .clear],
                        center: UnitPoint(x: 0.5, y: 1.15),
                        startRadius: 0, endRadius: w * 1.2
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: w * 0.07)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.25), Theme.raceRed.opacity(0.4)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )

            // Faint circuit-outline watermark behind the details.
            TrackOutlineShape(circuitID: "monteCarlo")
                .stroke(.white.opacity(0.05), lineWidth: 1.5)
                .frame(width: w * 0.7, height: w * 0.5)
                .offset(y: w * 0.02)

            // Diagonal red accent slash below the header.
            RedSlash()
                .fill(Theme.raceRed)
                .frame(height: w * 0.14)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, w * 0.42)
                .opacity(0.9)
                .mask(RoundedRectangle(cornerRadius: w * 0.07))

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    Image("grid_logo")
                        .resizable().scaledToFit()
                        .frame(width: w * 0.15)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("GRID")
                            .font(.gilroy(w * 0.12, .black)).italic()
                            .foregroundStyle(.white)
                        Text("PRO MEMBER")
                            .font(.gilroy(w * 0.038, .heavy))
                            .kerning(w * 0.012)
                            .foregroundStyle(Theme.raceRed)
                    }
                }
                .padding(.horizontal, w * 0.08)
                .padding(.top, w * 0.08)

                // Clear the diagonal slash before the name starts.
                Spacer(minLength: w * 0.38)

                // Name
                Text("MEMBER")
                    .font(.gilroy(w * 0.032, .bold))
                    .kerning(w * 0.014)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, w * 0.08)
                Text(driverName.uppercased())
                    .font(.gilroy(w * 0.10, .black))
                    .fontWidth(.condensed)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, w * 0.08)

                Spacer(minLength: w * 0.06)

                // Membership detail grid
                HStack(spacing: 0) {
                    detailCell("TIER", "FOUNDING", w)
                    detailCell("JOINED", joinedLabel, w)
                }
                .padding(.horizontal, w * 0.08)
                HStack(spacing: 0) {
                    detailCell("ACCESS", "ALL AREAS", w)
                    detailCell("STATUS", "ACTIVE", w)
                }
                .padding(.horizontal, w * 0.08)
                .padding(.top, w * 0.04)

                Spacer(minLength: w * 0.06)

                // Bottom: member no + barcode, signature next to the sticker
                HStack(alignment: .bottom, spacing: w * 0.03) {
                    VStack(alignment: .leading, spacing: w * 0.015) {
                        Text("MEMBER NO.")
                            .font(.gilroy(w * 0.028, .bold))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(String(format: "%04d", memberNumber))
                            .font(.system(size: w * 0.045, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                        BarcodeStripView(seed: memberNumber &* 7919 &+ driverName.hashValue)
                            .frame(width: w * 0.34, height: w * 0.075)
                            .padding(.top, w * 0.005)
                    }
                    Spacer(minLength: 0)
                    // Signature writing in, next to the holo sticker.
                    VStack(alignment: .trailing, spacing: w * 0.008) {
                        Image("signature")
                            .resizable().scaledToFit()
                            .frame(height: w * 0.17)
                            .mask(
                                GeometryReader { geo in
                                    Rectangle().frame(width: geo.size.width * sigProgress)
                                }
                            )
                        Text("SIGNED")
                            .font(.gilroy(w * 0.024, .bold))
                            .kerning(w * 0.008)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    HolographicSticker()
                        .frame(width: w * 0.22, height: w * 0.22)
                }
                .padding(.horizontal, w * 0.08)
                .padding(.bottom, w * 0.08)
            }
        }
        .shadow(color: Theme.raceRed.opacity(0.25), radius: 30, y: 12)
        .shadow(color: .black.opacity(0.6), radius: 18, y: 10)
    }

    // MARK: - Back (trophy cabinet)

    private func cardBack(width w: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.07)
                .fill(Color(white: 0.05))
                .overlay(
                    RadialGradient(
                        colors: [Theme.raceRed.opacity(0.45), .clear],
                        center: UnitPoint(x: 0.5, y: -0.15),
                        startRadius: 0, endRadius: w * 1.2
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: w * 0.07)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.25), Theme.raceRed.opacity(0.4)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )

            VStack(spacing: w * 0.045) {
                VStack(spacing: w * 0.012) {
                    Text("TROPHY CABINET")
                        .font(.gilroy(w * 0.052, .black))
                        .kerning(w * 0.01)
                        .foregroundStyle(.white)
                    Text("\(driverName.uppercased()) · \(finishedSessions) SESSIONS")
                        .font(.gilroy(w * 0.03, .bold))
                        .foregroundStyle(Theme.raceRed)
                }
                .padding(.top, w * 0.11)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3),
                          spacing: w * 0.05) {
                    ForEach(Achievements.all) { trophy in
                        trophyStamp(trophy,
                                    earned: trophy.isEarned(finishedSessions: finishedSessions),
                                    w: w)
                    }
                }
                .padding(.horizontal, w * 0.04)

                Spacer(minLength: 0)

                Text("TAP TO FLIP")
                    .font(.gilroy(w * 0.026, .bold))
                    .kerning(w * 0.01)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, w * 0.07)
            }
            .padding(.horizontal, w * 0.07)
        }
        .shadow(color: Theme.raceRed.opacity(0.25), radius: 30, y: 12)
        .shadow(color: .black.opacity(0.6), radius: 18, y: 10)
    }

    private func trophyStamp(_ trophy: Achievement, earned: Bool, w: CGFloat) -> some View {
        VStack(spacing: w * 0.014) {
            ZStack {
                Circle()
                    .strokeBorder(
                        earned ? Theme.gold.opacity(0.85) : .white.opacity(0.12),
                        style: StrokeStyle(lineWidth: w * 0.006,
                                           dash: [w * 0.022, w * 0.014])
                    )
                    .frame(width: w * 0.17, height: w * 0.17)
                Image(systemName: earned ? trophy.icon : "lock.fill")
                    .font(.system(size: w * 0.062, weight: .black))
                    .foregroundStyle(earned ? Theme.gold : .white.opacity(0.16))
            }
            Text(earned ? trophy.name.uppercased() : "\(trophy.sessions)")
                .font(.gilroy(w * 0.022, .bold))
                .foregroundStyle(earned ? .white.opacity(0.8) : .white.opacity(0.25))
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .rotationEffect(.degrees(earned ? Double(trophy.sessions % 7) - 3 : 0))
    }

    private func detailCell(_ label: String, _ value: String, _ w: CGFloat,
                            valueColor: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: w * 0.008) {
            Text(label)
                .font(.gilroy(w * 0.026, .bold))
                .kerning(w * 0.006)
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.gilroy(w * 0.038, .heavy))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Diagonal parallelogram used as the red accent slash.
private struct RedSlash: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let skew = rect.height * 0.9
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY - skew))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - skew))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Circular holographic "GRID" foil sticker — a SwiftUI recreation of the
/// classic CSS holo sticker: pastel radial base under two counter-rotating
/// conic gradients (soft-light) for the iridescent shimmer, a white die-cut
/// ring, and the skewed GRID wordmark blended into the foil.
struct HolographicSticker: View {
    /// Two multi-stop conic gradients that produce the metallic banding.
    private static let bandStops: [Color] = [
        .white, .white, Color(white: 0.73), .black, .black, Color(white: 0.73),
        .white, .white, Color(white: 0.73), .black, .black, Color(white: 0.73),
        .white, .white, Color(white: 0.73), .black, .black, Color(white: 0.73),
        .white, .white, Color(white: 0.73), .black, .black, Color(white: 0.73), .white,
    ]
    private static let sweepStops: [Color] = [
        .white, .black, .white, .black, .white, .black, .white, .black, .white,
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let slow = Angle.degrees((t / 80).truncatingRemainder(dividingBy: 1) * 360)
            let fast = Angle.degrees((t / 40).truncatingRemainder(dividingBy: 1) * 360)

            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)
                ZStack {
                    // Red iridescent radial base (light source top-left).
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "FF8A9B"), Color(hex: "E10A17"),
                                         Color(hex: "7A0A12"), Color(hex: "FF6B8A"),
                                         Color(hex: "3A0508")],
                                center: UnitPoint(x: 0.15, y: 0.15),
                                startRadius: 0, endRadius: s
                            )
                        )

                    // Slow banding layer.
                    Circle()
                        .fill(AngularGradient(colors: Self.bandStops, center: .center))
                        .rotationEffect(slow)
                        .blendMode(.softLight)
                        .opacity(0.3)

                    // Fast alternating sweep.
                    Circle()
                        .fill(AngularGradient(colors: Self.sweepStops, center: .center))
                        .rotationEffect(fast)
                        .blendMode(.softLight)
                        .opacity(0.5)

                    // Inner die-cut ring holding the wordmark.
                    Circle()
                        .strokeBorder(.black, lineWidth: s * 0.03)
                        .frame(width: s * 0.8, height: s * 0.8)
                        .overlay(gridWordmark(s: s * 0.8))
                        .rotationEffect(.degrees(10))
                        .blendMode(.overlay)
                }
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: s * 0.03))
                .frame(width: s, height: s)
            }
        }
    }

    /// The GRID letters, skewed and stacked on a diagonal like the original.
    private func gridWordmark(s: CGFloat) -> some View {
        let letters: [(String, Double, CGFloat, CGFloat)] = [
            ("G",  20, -0.24, -0.22),
            ("R",  20, -0.02, -0.04),
            ("I", -20,  0.14,  0.14),
            ("D", -20,  0.30,  0.26),
        ]
        return ZStack {
            ForEach(letters, id: \.0) { letter, skew, dx, dy in
                Text(letter)
                    .font(.gilroy(s * 0.34, .black))
                    .foregroundStyle(.black)
                    .modifier(SkewX(degrees: skew))
                    .offset(x: dx * s, y: dy * s)
            }
        }
    }
}

/// Horizontal skew transform (CSS skewX equivalent).
private struct SkewX: ViewModifier {
    let degrees: Double
    func body(content: Content) -> some View {
        content.transformEffect(
            CGAffineTransform(a: 1, b: 0, c: CGFloat(tan(degrees * .pi / 180)), d: 1, tx: 0, ty: 0)
        )
    }
}

/// Full-screen reveal of the Pro pass — dims the world, floats the card in
/// the centre with 3D tilt, and hands back on "Enter Grid".
struct ProPassRevealView: View {
    let driverName: String
    var memberNumber: Int = 1
    let onEnter: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            // Dim + red vignette behind the card.
            Color.black.opacity(0.9).ignoresSafeArea()
            RadialGradient(colors: [Theme.raceRed.opacity(0.3), .clear],
                           center: .center, startRadius: 40, endRadius: 420)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("YOU'RE IN.")
                    .font(.gilroy(30, .black)).kerning(1)
                    .foregroundStyle(.white)
                    .opacity(appear ? 1 : 0)

                GridProPassView(driverName: driverName, memberNumber: memberNumber,
                                animateSignature: true)
                    .frame(width: 250)
                    .scaleEffect(appear ? 1 : 0.7)
                    .rotationEffect(.degrees(appear ? 0 : -8))
                    .opacity(appear ? 1 : 0)

                Text("Tilt to watch it shine.")
                    .font(.gilroy(12, .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .opacity(appear ? 1 : 0)

                Spacer()

                Button {
                    Haptics.impact(.medium)
                    onEnter()
                } label: {
                    Text("ENTER GRID")
                        .font(.gilroy(17, .bold)).kerning(1.5)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            MotionTilt.shared.start()
            Haptics.success()
            withAnimation(.spring(duration: 0.7, bounce: 0.35)) { appear = true }
        }
    }
}
