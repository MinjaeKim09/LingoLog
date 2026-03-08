import Foundation
import StoreKit
import os

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // MARK: - Product IDs
    
    static let dailyStoriesProductID = "com.lingolog.dailystories"
    
    // MARK: - Published State
    
    @Published private(set) var isStoryUnlocked: Bool = false
    @Published private(set) var dailyStoriesProduct: Product?
    @Published private(set) var purchaseError: String?
    @Published private(set) var isPurchasing: Bool = false
    
    // MARK: - Private
    
    private var transactionListener: Task<Void, Error>?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LingoLog", category: "store")
    
    // MARK: - Init
    
    private init() {
        // Check persisted purchase state immediately
        isStoryUnlocked = UserDefaults.standard.bool(forKey: "isStoryUnlocked")
        
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Verify entitlements on launch
        Task {
            await verifyEntitlements()
            await fetchProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [Self.dailyStoriesProductID])
            if let product = products.first {
                dailyStoriesProduct = product
                logger.info("Fetched product: \(product.displayName) — \(product.displayPrice)")
            } else {
                logger.warning("Daily stories product not found in store.")
            }
        } catch {
            logger.error("Failed to fetch products: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase() async {
        guard let product = dailyStoriesProduct else {
            purchaseError = "Product not available. Please try again later."
            return
        }
        
        isPurchasing = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                unlockStories()
                logger.info("Purchase successful!")
                
            case .userCancelled:
                logger.info("User cancelled purchase.")
                
            case .pending:
                logger.info("Purchase pending (e.g. Ask to Buy).")
                
            @unknown default:
                logger.warning("Unknown purchase result.")
            }
        } catch {
            purchaseError = error.localizedDescription
            logger.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
        }
        
        isPurchasing = false
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        
        do {
            try await AppStore.sync()
            await verifyEntitlements()
            
            if !isStoryUnlocked {
                purchaseError = "No previous purchase found."
            }
        } catch {
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
            logger.error("Restore failed: \(error.localizedDescription, privacy: .public)")
        }
        
        isPurchasing = false
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self?.checkVerified(result)
                    }
                    if let transaction = transaction {
                        await transaction.finish()
                        await self?.unlockStories()
                    }
                } catch {
                    await MainActor.run {
                        self?.logger.error("Transaction verification failed: \(error.localizedDescription, privacy: .public)")
                    }
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
    
    private func verifyEntitlements() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == Self.dailyStoriesProductID {
                    unlockStories()
                    return
                }
            } catch {
                logger.error("Entitlement verification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Unlock
    
    private func unlockStories() {
        isStoryUnlocked = true
        UserDefaults.standard.set(true, forKey: "isStoryUnlocked")
    }
}
