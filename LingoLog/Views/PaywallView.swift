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
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accent.opacity(0.2), Theme.Colors.secondaryAccent.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.secondaryAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Title
                    VStack(spacing: 8) {
                        Theme.Typography.display("Daily Stories")
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Theme.Typography.body("Subscribe for AI-generated stories from your vocabulary")
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Feature List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "sparkles",
                            title: "AI-Generated Stories",
                            subtitle: "Personalized stories using your vocabulary"
                        )
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "Comprehension Quizzes",
                            subtitle: "Test your understanding after each story"
                        )
                        FeatureRow(
                            icon: "calendar",
                            title: "Daily Fresh Content",
                            subtitle: "Generate one new story each day"
                        )
                        FeatureRow(
                            icon: "lock.shield",
                            title: "Private App Data",
                            subtitle: "Your vocabulary stays saved on this device"
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
                                        Image(systemName: "sparkles")
                                        Text("Subscribe for \(product.displayPrice) / month")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .font(.headline)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.Colors.accent, Theme.Colors.secondaryAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                            }
                            .disabled(storeManager.isPurchasing)
                        } else {
                            ProgressView("Loading price...")
                                .tint(Theme.Colors.accent)
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
                        
                        if let termsURL = AppConfig.termsOfServiceURL,
                           let privacyURL = AppConfig.privacyPolicyURL {
                            Text("Subscription renews monthly until canceled. Manage or cancel anytime in your Apple ID subscriptions.")
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 12) {
                                Link("Terms", destination: termsURL)
                                Link("Privacy", destination: privacyURL)
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
        .onChange(of: storeManager.isDailyStoriesActive) { _, active in
            if active {
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
