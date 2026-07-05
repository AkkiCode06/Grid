import Foundation
import StoreKit

/// StoreKit 2 subscription unlock for Grid Pro. Backed by a local
/// `Grid.storekit` configuration for on-device testing until real App Store
/// Connect products exist. Grants full access while any unlocking product is
/// entitled (either Pro subscription, or the legacy one-time unlock).
@Observable
final class StoreService {
    static let shared = StoreService()

    private(set) var hasFullAccess: Bool
    /// Loaded Pro products, keyed by product ID.
    private(set) var products: [String: Product] = [:]
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

    // MARK: - Products

    var yearly: Product? { products[AppConfig.proYearlyProductID] }
    var monthly: Product? { products[AppConfig.proMonthlyProductID] }

    func start() async {
        listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        guard let loaded = try? await Product.products(for: AppConfig.proProductIDs) else { return }
        var map: [String: Product] = [:]
        for product in loaded { map[product.id] = product }
        products = map
    }

    // MARK: - Purchase / restore

    /// Purchase a specific product by ID. Returns true when access is granted.
    @discardableResult
    func purchase(productID: String) async -> Bool {
        var product = products[productID]
        if product == nil {
            await loadProducts()
            product = products[productID]
        }
        guard let product else { return false }
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                grantFullAccess()
                await transaction.finish()
                return true
            }
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Entitlements

    private func refreshEntitlements() async {
        var entitled = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               AppConfig.unlockingProductIDs.contains(transaction.productID) {
                entitled = true
            }
        }
        if entitled { grantFullAccess() }
    }

    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    if AppConfig.unlockingProductIDs.contains(transaction.productID) {
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
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "debugFullAccess")
        #endif
    }

    #if DEBUG
    /// Developer-only override to flip entitlement state for testing paywalls.
    func debugSetFullAccess(_ value: Bool) {
        hasFullAccess = value
        UserDefaults.standard.set(value, forKey: "debugFullAccess")
    }
    #endif
}
