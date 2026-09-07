import SwiftUI

struct NoWordsView: View {
    var body: some View {
        VStack(spacing: 20) {
            IconTile(symbol: "checkmark", color: Theme.Colors.success, size: 64)
            
            Theme.Typography.title("You’re caught up")
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Theme.Typography.body("Everything is up to date. Add another word or come back after the next review is ready.")
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .glassCard()
        .padding()
    }
}
