import SwiftUI
import StoreKit

/// One-time unlock for all circuits and seats. Product IDs live in AppConfig;
/// until they exist in App Store Connect this degrades to an informative
/// stub so the flow is still navigable.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var purchasing = false

    private var store: StoreService { StoreService.shared }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.gold)
                    Text("FULL SEASON PASS")
                        .font(.telemetry(18, weight: .black))
                        .kerning(3)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Every circuit. Every grandstand. Forever.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 32)

                VStack(spacing: 10) {
                    ForEach(CircuitLibrary.all) { circuit in
                        HStack {
                            Text(circuit.flag)
                            Text(circuit.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: circuit.isFree ? "checkmark.circle.fill" : "lock.open.fill")
                                .foregroundStyle(circuit.isFree ? .green : Theme.gold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        purchasing = true
                        Task {
                            let success = await store.purchaseUnlock()
                            purchasing = false
                            if success { dismiss() }
                        }
                    } label: {
                        Group {
                            if purchasing {
                                ProgressView()
                            } else if let product = store.unlockProduct {
                                Text("UNLOCK EVERYTHING — \(product.displayPrice)")
                            } else {
                                Text("UNLOCK EVERYTHING")
                            }
                        }
                        .font(.telemetry(14, weight: .bold))
                        .kerning(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.raceRed, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .disabled(purchasing || store.unlockProduct == nil)

                    if store.unlockProduct == nil {
                        Text("Purchases aren't configured for this build yet.")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
