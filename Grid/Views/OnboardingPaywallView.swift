import SwiftUI

/// A "you just hit a wall" context passed to the paywall when the user taps a
/// Pro-gated feature. Drives a loss-aversion banner at the top of the sheet.
struct PaywallLock: Identifiable {
    let id = UUID()
    let icon: String
    /// Big line naming exactly what they can't have.
    let headline: String
    /// FOMO pitch — what they're missing out on, made concrete.
    let pitch: String

    /// A specific locked circuit the user tried to race.
    static func circuit(_ c: Circuit) -> PaywallLock {
        let freeCount = CircuitLibrary.all.filter { $0.isFree && !$0.isCustom }.count
        let totalCount = CircuitLibrary.all.filter { !$0.isCustom }.count
        return PaywallLock(
            icon: "flag.checkered",
            headline: "\(c.name) is locked",
            pitch: "You've got \(freeCount) of \(totalCount) circuits. The other \(totalCount - freeCount) tracks — plus every team livery — stay behind the wall until you go Pro."
        )
    }

    /// The Pass Studio (custom pass designer).
    static let passStudio = PaywallLock(
        icon: "paintbrush.pointed.fill",
        headline: "Pass Studio is Pro turf",
        pitch: "Design your own holographic paddock pass, unlock every livery, and carry the 3D Pro membership card. All locked right now."
    )
}

/// Onboarding paywall — presentation only. Slides up after "Welcome to Grid".
/// No StoreKit wired in yet; the CTA reveals the Pro membership pass then
/// calls `onFinish`. Prices/copy are placeholders in the shape major
/// subscription apps use. When `lock` is set, the sheet leads with a
/// loss-aversion banner instead of the neutral logo header.
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

    private struct Feature: Identifiable {
        let icon: String
        let text: String
        var id: String { text }
    }

    private let features: [Feature] = [
        Feature(icon: "flag.checkered", text: "All 12 circuits"),
        Feature(icon: "paintpalette.fill", text: "Every team livery"),
        Feature(icon: "paintbrush.pointed.fill", text: "Pass Studio + holo pass"),
        Feature(icon: "chart.bar.fill", text: "Full focus stats"),
        Feature(icon: "bolt.shield.fill", text: "Race-control flags"),
        Feature(icon: "sparkles", text: "3D Pro membership pass"),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            paywall
        }
    }

    // MARK: - Paywall

    private var paywall: some View {
        VStack(spacing: 0) {
            closeButton

            if let lock {
                fomoBanner(lock)
            } else {
                Image("grid_logo")
                    .resizable().scaledToFit()
                    .frame(width: 52)
                    .padding(.bottom, 8)
                Text("GRID PRO")
                    .font(.gilroy(24, .black))
                    .kerning(1)
                    .foregroundStyle(.white)
                Text("Everything unlocked.")
                    .font(.gilroy(14, .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 18)
            }

            // Feature chips — two columns, icon-forward
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                                GridItem(.flexible(), alignment: .leading)],
                      spacing: 12) {
                ForEach(features) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.white.opacity(0.08), in: Circle())
                        Text(feature.text)
                            .font(.gilroy(13, .semiBold))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)

            planCards
            promoRow
            cta
        }
    }

    // MARK: - FOMO banner (locked-feature entry)

    private func fomoBanner(_ lock: PaywallLock) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.raceRed.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: lock.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.raceRed)
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Theme.raceRed, in: Circle())
                    .offset(x: 22, y: 20)
            }
            .padding(.bottom, 2)

            Text("YOU JUST HIT A WALL")
                .font(.gilroy(11, .black)).kerning(2)
                .foregroundStyle(Theme.raceRed)

            Text(lock.headline)
                .font(.gilroy(22, .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.8)

            Text(lock.pitch)
                .font(.gilroy(13, .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 18)
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                Haptics.impact(.light)
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(9)
                    .background(.white.opacity(0.08), in: Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: "$29.99",
                     unit: "/yr", sub: "$2.50/mo · 7-day free trial", badge: "SAVE 50%")
            planCard(.monthly, title: "Monthly", price: "$4.99",
                     unit: "/mo", sub: "Cancel anytime", badge: nil)
        }
        .padding(.horizontal, 24)
    }

    private func planCard(_ plan: Plan, title: String, price: String, unit: String, sub: String, badge: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            Haptics.impact(.light)
            withAnimation(.snappy(duration: 0.2)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Theme.raceRed : .white.opacity(0.3))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text(title).font(.gilroy(16, .bold)).foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.gilroy(9, .black)).kerning(0.5)
                                .padding(.horizontal, 6).padding(.vertical, 2.5)
                                .background(Theme.raceRed.opacity(0.9), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(sub).font(.gilroy(11, .medium)).foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(price).font(.gilroy(15, .heavy)).foregroundStyle(.white)
                    Text(unit).font(.gilroy(11, .bold)).foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(14)
            .background(selected ? Theme.raceRed.opacity(0.10) : Color.white.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? Theme.raceRed.opacity(0.8) : .white.opacity(0.08),
                                  lineWidth: selected ? 1.5 : 1)
            )
        }
    }

    // MARK: - Promo

    private var promoRow: some View {
        VStack(spacing: 10) {
            if showPromo {
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.raceRed)
                    TextField("Enter code", text: $promoCode)
                        .font(.gilroy(14, .semiBold))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    Button {
                        Haptics.success()
                        onSubscribe()   // treat a code as a gifted pass
                    } label: {
                        Text("REDEEM")
                            .font(.gilroy(12, .bold))
                            .foregroundStyle(promoCode.isEmpty ? .white.opacity(0.3) : Theme.raceRed)
                    }
                    .disabled(promoCode.isEmpty)
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)
            } else {
                Button {
                    Haptics.impact(.light)
                    withAnimation(.snappy) { showPromo = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gift")
                        Text("Have a promo code?")
                    }
                    .font(.gilroy(13, .semiBold))
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - CTA

    private var cta: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.success()
                onSubscribe()
            } label: {
                Text(selectedPlan == .yearly ? "START 7-DAY FREE TRIAL" : "SUBSCRIBE")
                    .font(.gilroy(16, .bold)).kerning(1.5)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            HStack(spacing: 16) {
                Text("Restore"); Text("·"); Text("Terms"); Text("·"); Text("Privacy")
            }
            .font(.gilroy(11, .medium))
            .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }
}
