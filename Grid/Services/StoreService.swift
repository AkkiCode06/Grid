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
        #if DEBUG
        // Default to unlocked in DEBUG, but let the Developer toggle override it
        // so paywalls / locked states can actually be exercised.
        if UserDefaults.standard.object(forKey: "debugFullAccess") != nil {
            hasFullAccess = UserDefaults.standard.bool(forKey: "debugFullAccess")
        } else {
            hasFullAccess = true
        }
        #else
        hasFullAccess = UserDefaults.standard.bool(forKey: "hasFullAccess")
        #endif
    }

    #if DEBUG
    /// Developer-only override to flip entitlement state for testing paywalls.
    func debugSetFullAccess(_ value: Bool) {
        hasFullAccess = value
        UserDefaults.standard.set(value, forKey: "debugFullAccess")
    }
    #endif

    /// Unlock used by the UI-only paywall (Subscribe / Redeem) until real
    /// StoreKit purchasing is wired in. Persists so it survives relaunch.
    func grantPlaceholderUnlock() {
        grantFullAccess()
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "debugFullAccess")
        #endif
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
