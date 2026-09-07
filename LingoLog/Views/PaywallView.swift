import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storeManager: StoreManager
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
                        }
                    }
                    .padding(.top, 8)
                    
                    // Hero Icon
                    Image(systemName: "books.vertical.fill")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Theme.Colors.accent)
                    
                    // Title
                    VStack(spacing: 8) {
                        Theme.Typography.display("Daily Stories + Spaces")
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Theme.Typography.body("Unlock personalized daily reading and a separate space for every language you learn")
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Feature List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "text.book.closed.fill",
                            title: "Personalized Stories",
                            subtitle: "Personalized stories using your vocabulary"
                        )
                        FeatureRow(
                            icon: "checkmark.bubble.fill",
                            title: "Comprehension Quizzes",
                            subtitle: "Test your understanding after each story"
                        )
                        FeatureRow(
                            icon: "calendar.badge.clock",
                            title: "Daily Fresh Content",
                            subtitle: "Generate one new story each day"
                        )
                        FeatureRow(
                            icon: "books.vertical.fill",
                            title: "Language Spaces",
                            subtitle: "Keep every language’s words, reviews, and stories separate"
                        )
                    }
                    .padding(20)
                    .glassCard()
                    
                    // Price + Buy Button
                    VStack(spacing: 12) {
                        if let product = storeManager.dailyStoriesProduct {
                            Button(action: {
                                Task { await storeManager.purchase() }
                            }) {
                                HStack {
                                    if storeManager.isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "lock.open.fill")
                                        Text("Subscribe for \(product.displayPrice) / month")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle()
                            .disabled(storeManager.isPurchasing)
                        } else if storeManager.isLoadingProducts {
                            ProgressView("Loading price...")
                                .tint(Theme.Colors.accent)
                        } else {
                            Button(action: {
                                Task { await storeManager.fetchProducts() }
                            }) {
                                Label("Try Again", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle()
                            .disabled(storeManager.isPurchasing)
                        }
                        
                        // Restore Purchases
                        Button(action: {
                            Task { await storeManager.restorePurchases() }
                        }) {
                            Text("Restore Purchases")
                                .font(.body)
                                .foregroundStyle(Theme.Colors.accent)
                        }
                        .disabled(storeManager.isPurchasing)
                        
                        Text("Subscription renews monthly until canceled. Manage or cancel anytime in your Apple ID subscriptions.")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                        if AppConfig.termsOfServiceURL != nil || AppConfig.privacyPolicyURL != nil {
                            HStack(spacing: 12) {
                                if let termsURL = AppConfig.termsOfServiceURL {
                                    Link("Terms", destination: termsURL)
                                }
                                if let privacyURL = AppConfig.privacyPolicyURL {
                                    Link("Privacy", destination: privacyURL)
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    
                    // Error
                    if let error = storeManager.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.error)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .onChange(of: storeManager.isStoryUnlocked) { _, unlocked in
            if unlocked {
                dismiss()
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    PaywallView(storeManager: StoreManager.shared)
}
