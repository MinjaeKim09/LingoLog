import Foundation
import StoreKit
import UIKit
import os

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // MARK: - Product IDs
    
    static let dailyStoriesMonthlyProductID = "com.lingolog.dailystories.monthly"
    
    // MARK: - Published State
    
    @Published private(set) var isDailyStoriesActive: Bool = false
    @Published private(set) var dailyStoriesProduct: Product?
    @Published private(set) var purchaseError: String?
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var latestSubscriptionJWS: String?

#if DEBUG
    /// Debug builds can use this to exercise the protected Daily Stories flow before
    /// the App Store Connect subscription has been created.
    @Published private(set) var developerDailyStoriesOverride: Bool
    private static let developerOverridePreferenceKey = "developerDailyStoriesOverride"
    private static let developerSubscriptionProof = "lingolog-debug-subscription-proof"
#endif
    
    var isStoryUnlocked: Bool {
#if DEBUG
        isDailyStoriesActive || developerDailyStoriesOverride
#else
        isDailyStoriesActive
#endif
    }

    /// Language Spaces are bundled with the Daily Stories subscription. A primary
    /// learning language remains available so core flashcard study works for everyone.
    var isLanguageSpacesUnlocked: Bool {
        isStoryUnlocked
    }

    var storySubscriptionJWS: String? {
#if DEBUG
        if developerDailyStoriesOverride {
            return Self.developerSubscriptionProof
        }
#endif
        return latestSubscriptionJWS
    }
    
    // MARK: - Private
    
    private var transactionListener: Task<Void, Never>?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LingoLog", category: "store")
    
    // MARK: - Init
    
    private init() {
#if DEBUG
        developerDailyStoriesOverride = UserDefaults.standard.bool(forKey: Self.developerOverridePreferenceKey)
#endif
        transactionListener = listenForTransactions()
        
        Task {
            await verifyEntitlements()
            await fetchProducts()
        }
    }

#if DEBUG
    func setDeveloperDailyStoriesOverride(_ enabled: Bool) {
        developerDailyStoriesOverride = enabled
        UserDefaults.standard.set(enabled, forKey: Self.developerOverridePreferenceKey)
    }
#endif
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async {
        isLoadingProducts = true
        purchaseError = nil
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [Self.dailyStoriesMonthlyProductID])
            if let product = products.first {
                dailyStoriesProduct = product
                logger.info("Fetched product: \(product.displayName) - \(product.displayPrice)")
            } else {
                dailyStoriesProduct = nil
                purchaseError = "Daily Stories is not available right now. Please try again later."
                logger.warning("Daily Stories subscription product not found.")
            }
        } catch {
            dailyStoriesProduct = nil
            purchaseError = "Unable to load the subscription. Check your connection and try again."
            logger.error("Failed to fetch products: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase() async {
        guard let product = dailyStoriesProduct else {
            purchaseError = "Subscription is not available. Please try again later."
            return
        }
        
        isPurchasing = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await apply(transaction, jwsRepresentation: verification.jwsRepresentation)
                await transaction.finish()
                logger.info("Subscription purchase successful.")
                
            case .userCancelled:
                logger.info("User cancelled subscription purchase.")
                
            case .pending:
                logger.info("Subscription purchase pending.")
                
            @unknown default:
                logger.warning("Unknown purchase result.")
            }
        } catch {
            purchaseError = error.localizedDescription
            logger.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
        }
        
        isPurchasing = false
    }
    
    // MARK: - Restore + Manage
    
    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        
        do {
            try await AppStore.sync()
            await verifyEntitlements()
            
            if !isDailyStoriesActive {
                purchaseError = "No active Daily Stories subscription found."
            }
        } catch {
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
            logger.error("Restore failed: \(error.localizedDescription, privacy: .public)")
        }
        
        isPurchasing = false
    }
    
    func manageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            purchaseError = "Unable to open subscription management right now."
            return
        }
        
        do {
            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            purchaseError = "Unable to open subscription management: \(error.localizedDescription)"
            logger.error("Manage subscriptions failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction {
                        await self?.apply(transaction, jwsRepresentation: result.jwsRepresentation)
                        await transaction.finish()
                    }
                } catch {
                    self?.logger.error("Transaction verification failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let signedType):
            return signedType
        }
    }
    
    func verifyEntitlements() async {
        var activeTransaction: Transaction?
        var activeJWS: String?
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if isActiveDailyStoriesTransaction(transaction) {
                    activeTransaction = transaction
                    activeJWS = result.jwsRepresentation
                    break
                }
            } catch {
                logger.error("Entitlement verification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        if let activeTransaction {
            applyActive(transaction: activeTransaction, jwsRepresentation: activeJWS)
        } else {
            applyInactive()
        }
    }
    
    private func apply(_ transaction: Transaction, jwsRepresentation: String?) async {
        if isActiveDailyStoriesTransaction(transaction) {
            applyActive(transaction: transaction, jwsRepresentation: jwsRepresentation)
        } else if transaction.productID == Self.dailyStoriesMonthlyProductID {
            await verifyEntitlements()
        }
    }
    
    private func isActiveDailyStoriesTransaction(_ transaction: Transaction) -> Bool {
        guard transaction.productID == Self.dailyStoriesMonthlyProductID else { return false }
        guard transaction.revocationDate == nil else { return false }
        
        if let expirationDate = transaction.expirationDate {
            return expirationDate > Date()
        }
        
        return true
    }
    
    private func applyActive(transaction: Transaction, jwsRepresentation: String?) {
        isDailyStoriesActive = true
        latestSubscriptionJWS = jwsRepresentation
    }
    
    private func applyInactive() {
        isDailyStoriesActive = false
        latestSubscriptionJWS = nil
    }
}
