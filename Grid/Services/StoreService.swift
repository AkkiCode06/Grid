import Foundation
import StoreKit

/// StoreKit 2 one-time purchase unlocking all circuits and seats.
/// Product IDs are configurable in AppConfig; the paywall degrades gracefully
/// when products aren't configured in App Store Connect yet.
@Observable
final class StoreService {
    static let shared = StoreService()

    private(set) var hasFullAccess: Bool
    private(set) var unlockProduct: Product?
    private var updatesTask: Task<Void, Never>?

    private init() {
        hasFullAccess = UserDefaults.standard.bool(forKey: "hasFullAccess")
    }

    func start() async {
        listenForTransactions()
        await refreshEntitlements()
        unlockProduct = try? await Product.products(
            for: [AppConfig.fullUnlockProductID]
        ).first
    }

    @discardableResult
    func purchaseUnlock() async -> Bool {
        guard let product = unlockProduct else { return false }
        guard let result = try? await product.purchase() else { return false }
        if case .success(let verification) = result,
           case .verified(let transaction) = verification {
            grantFullAccess()
            await transaction.finish()
            return true
        }
        return false
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == AppConfig.fullUnlockProductID {
                grantFullAccess()
            }
        }
    }

    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    if transaction.productID == AppConfig.fullUnlockProductID {
                        await MainActor.run { self?.grantFullAccess() }
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func grantFullAccess() {
        hasFullAccess = true
        UserDefaults.standard.set(true, forKey: "hasFullAccess")
    }
}
