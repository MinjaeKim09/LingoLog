import SwiftUI

struct NoWordsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.success)
            
            Theme.Typography.title("No words due for review!")
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Theme.Typography.body("Great job! All your words are up to date. Add some new words to start learning.")
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .glassCard()
        .padding()
    }
}
