import SwiftUI

/// Onboarding paywall — presentation only. Slides up after "Welcome to Grid".
/// No StoreKit wired in yet; the CTA just calls `onFinish`. Prices/copy are
/// placeholders in the shape major subscription apps use.
struct OnboardingPaywallView: View {
    /// Called when the user starts the trial or dismisses — hands control
    /// back to onboarding to finish and enter the app.
    let onFinish: () -> Void

    @State private var selectedPlan: Plan = .yearly

    private enum Plan { case yearly, monthly }

    private struct Feature: Identifiable {
        let icon: String
        let text: String
        var id: String { text }
    }

    private let features: [Feature] = [
        Feature(icon: "flag.checkered.2.crossed", text: "Every circuit — Monaco to the Ardennes"),
        Feature(icon: "person.2.fill", text: "All team liveries for your paddock pass"),
        Feature(icon: "paintbrush.pointed.fill", text: "Pass Studio + the holographic pass"),
        Feature(icon: "chart.bar.fill", text: "Full focus stats & race history"),
        Feature(icon: "bolt.shield.fill", text: "Live race-control flags while you're away"),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Theme.raceRed)
                                    .frame(width: 26)
                                Text(feature.text)
                                    .font(.gilroy(15, .semiBold))
                                    .foregroundStyle(.white)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                planCards
                cta
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button {
                    Haptics.impact(.light)
                    onFinish()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(10)
                        .background(.white.opacity(0.08), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Image("grid_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 64)

            Text("GO PRO")
                .font(.gilroy(30, .black))
                .kerning(1)
                .foregroundStyle(.white)
            Text("Unlock the full grid.")
                .font(.gilroy(15, .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 6)
        }
    }

    // MARK: - Plans

    private var planCards: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .yearly,
                title: "Yearly",
                price: "$29.99 / year",
                sub: "Just $2.50 / month · 7-day free trial",
                badge: "SAVE 50%"
            )
            planCard(
                plan: .monthly,
                title: "Monthly",
                price: "$4.99 / month",
                sub: "Billed monthly · cancel anytime",
                badge: nil
            )
        }
        .padding(.horizontal, 24)
    }

    private func planCard(plan: Plan, title: String, price: String, sub: String, badge: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            Haptics.impact(.light)
            withAnimation(.snappy(duration: 0.2)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Theme.raceRed : .white.opacity(0.3))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.gilroy(17, .bold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.gilroy(9, .black))
                                .kerning(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Theme.raceRed, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(sub)
                        .font(.gilroy(12, .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Text(price)
                    .font(.gilroy(14, .bold))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                selected ? Theme.raceRed.opacity(0.12) : Color.white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Theme.raceRed : .white.opacity(0.1), lineWidth: selected ? 1.5 : 1)
            )
        }
    }

    // MARK: - CTA

    private var cta: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.success()
                onFinish()
            } label: {
                Text(selectedPlan == .yearly ? "START 7-DAY FREE TRIAL" : "SUBSCRIBE")
                    .font(.gilroy(17, .bold))
                    .kerning(1.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 19)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }

            HStack(spacing: 18) {
                Text("Restore")
                Text("·")
                Text("Terms")
                Text("·")
                Text("Privacy")
            }
            .font(.gilroy(11, .medium))
            .foregroundStyle(.white.opacity(0.4))

            Text(selectedPlan == .yearly
                 ? "7 days free, then $29.99/year. Cancel anytime."
                 : "$4.99/month. Cancel anytime.")
                .font(.gilroy(10, .regular))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        OnboardingPaywallView(onFinish: {})
            .presentationDetents([.large])
    }
}
