import SwiftUI

/// A "you just hit a wall" context passed to the paywall when the user taps a
/// Pro-gated feature. Personalises the hero headline with loss-aversion copy.
struct PaywallLock: Identifiable {
    let id = UUID()
    let icon: String
    /// Short label of the thing they just hit, e.g. "Bay City Night Circuit".
    let feature: String
    /// Big line naming exactly what they can't have.
    let headline: String
    /// FOMO pitch — what they're missing out on, made concrete.
    let pitch: String
    /// Circuit to fly over in the backdrop, when the wall is a locked track.
    var circuitID: String? = nil

    /// A specific locked circuit the user tried to race.
    static func circuit(_ c: Circuit) -> PaywallLock {
        let freeCount = CircuitLibrary.all.filter { $0.isFree && !$0.isCustom }.count
        let totalCount = CircuitLibrary.all.filter { !$0.isCustom }.count
        return PaywallLock(
            icon: "flag.checkered",
            feature: c.name,
            headline: c.name,
            pitch: "You're racing \(freeCount) of \(totalCount) circuits. This one — and \(totalCount - freeCount - 1) more, in every livery — unlock with Pro.",
            circuitID: c.id
        )
    }

    /// The Pass Studio (custom pass designer).
    static let passStudio = PaywallLock(
        icon: "paintbrush.pointed.fill",
        feature: "Pass Studio",
        headline: "Pass Studio is Pro turf",
        pitch: "Design your own holographic paddock pass, unlock every livery, and carry the 3D Pro card. Locked right now."
    )
}

/// The Pro paywall — cinematic full-bleed. A live 3D flyover of the circuit
/// fills the screen (the locked track itself, when that's what you hit); the
/// pitch, value and plans sit low over a dark gradient with a pinned CTA.
/// Presentation only; the CTA grants a placeholder unlock and reveals the pass.
struct OnboardingPaywallView: View {
    /// Called when the user subscribes or redeems — the host then reveals the
    /// Pro membership pass.
    let onSubscribe: () -> Void
    /// Called when the user dismisses without subscribing.
    let onClose: () -> Void
    /// Optional locked-feature context that triggered this paywall.
    var lock: PaywallLock? = nil

    @State private var selectedPlan: Plan = .yearly
    @State private var showPromo = false
    @State private var promoCode = ""

    private enum Plan { case yearly, monthly }

    private let values: [String] = [
        "All 12 circuits, worldwide",
        "Every team livery",
        "Pass Studio + holographic pass",
        "Full focus stats, flags & Live Activity",
    ]

    /// The circuit whose flyover backs the paywall. Falls back to a marquee.
    private var backdropCircuitID: String {
        if let id = lock?.circuitID, CircuitGeo.coordinates(for: id) != nil { return id }
        return "monteCarlo"
    }

    private var eyebrow: String { lock == nil ? "GRID PRO" : "LOCKED" }
    private var headline: String { lock?.headline ?? "Race the full grid." }
    private var subhead: String {
        lock?.pitch ?? "Every circuit, every livery — and the pass that proves it."
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            backdrop
            scrim
            content
            closeButton
        }
        .background(Theme.background)
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        CircuitFlyoverView(circuitID: backdropCircuitID, isPaused: false, dualMode: false)
            .ignoresSafeArea()
    }

    /// Dark gradient so type stays legible over the moving footage.
    private var scrim: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.15), location: 0.0),
                .init(color: .black.opacity(0.55), location: 0.42),
                .init(color: .black.opacity(0.92), location: 0.72),
                .init(color: .black, location: 1.0),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if lock != nil { lockedFlag }

            Text(eyebrow)
                .font(.gilroy(12, .black)).kerning(3)
                .foregroundStyle(Theme.raceRed)
                .padding(.bottom, 8)

            Text(headline)
                .font(.gilroy(38, .heavy))
                .foregroundStyle(.white)
                .lineLimit(2).minimumScaleFactor(0.7)
                .shadow(color: .black.opacity(0.5), radius: 8, y: 2)

            Text(subhead)
                .font(.gilroy(15, .medium))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            valueRows
                .padding(.top, 18)

            planPills
                .padding(.top, 20)

            cta
                .padding(.top, 14)

            legalRow
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lockedFlag: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.fill").font(.system(size: 10, weight: .black))
            Text("YOU JUST HIT A WALL").font(.gilroy(10, .black)).kerning(1.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Theme.raceRed, in: Capsule())
        .padding(.bottom, 14)
    }

    private var valueRows: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(values, id: \.self) { text in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Theme.raceRed)
                        .frame(width: 18, height: 18)
                        .background(Theme.raceRed.opacity(0.16), in: Circle())
                    Text(text)
                        .font(.gilroy(14, .semiBold))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
        }
    }

    // MARK: - Plans

    private var planPills: some View {
        HStack(spacing: 10) {
            planPill(.yearly, title: "Yearly", price: "$29.99/yr",
                     note: "7-day free trial", badge: "SAVE 50%")
            planPill(.monthly, title: "Monthly", price: "$4.99/mo",
                     note: "Cancel anytime", badge: nil)
        }
    }

    private func planPill(_ plan: Plan, title: String, price: String, note: String, badge: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            Haptics.impact(.light)
            withAnimation(.snappy(duration: 0.2)) { selectedPlan = plan }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title).font(.gilroy(14, .bold)).foregroundStyle(.white)
                    if let badge {
                        Text(badge)
                            .font(.gilroy(8, .black)).kerning(0.5)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Theme.raceRed, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(price).font(.gilroy(18, .heavy)).foregroundStyle(.white)
                Text(note).font(.gilroy(10, .medium)).foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                (selected ? Theme.raceRed.opacity(0.18) : Color.white.opacity(0.06)),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Theme.raceRed : .white.opacity(0.12),
                                  lineWidth: selected ? 2 : 1)
            )
        }
    }

    // MARK: - CTA

    private var cta: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.success()
                onSubscribe()
            } label: {
                Text(selectedPlan == .yearly ? "START 7-DAY FREE TRIAL" : "UNLOCK GRID PRO")
                    .font(.gilroy(16, .bold)).kerning(1.5)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
            }
            Text(selectedPlan == .yearly ? "7 days free, then $29.99/yr · cancel anytime"
                                         : "$4.99/mo · cancel anytime")
                .font(.gilroy(11, .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var legalRow: some View {
        VStack(spacing: 10) {
            if showPromo {
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill").font(.system(size: 12)).foregroundStyle(Theme.raceRed)
                    TextField("Enter code", text: $promoCode)
                        .font(.gilroy(13, .semiBold))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    Button {
                        Haptics.success()
                        onSubscribe()
                    } label: {
                        Text("REDEEM").font(.gilroy(12, .bold))
                            .foregroundStyle(promoCode.isEmpty ? .white.opacity(0.3) : Theme.raceRed)
                    }
                    .disabled(promoCode.isEmpty)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 14) {
                Button(showPromo ? "Hide code" : "Have a promo code?") {
                    Haptics.impact(.light)
                    withAnimation(.snappy) { showPromo.toggle() }
                }
                Text("·")
                Text("Restore"); Text("·"); Text("Terms"); Text("·"); Text("Privacy")
            }
            .font(.gilroy(11, .medium))
            .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    Haptics.impact(.light)
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }
}
