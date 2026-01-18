import SwiftUI

struct NameOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager
    @State private var nameInput: String = ""
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Colors.accent)
                    
                    Theme.Typography.title("Welcome!")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    
                    Theme.Typography.body("What should we call you?")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, 40)
                
                // Input Field
                VStack(spacing: 8) {
                    TextField("Your Name", text: $nameInput)
                        .padding()
                        .background(Theme.Colors.inputBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.secondaryAccent.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(Theme.Colors.textPrimary)
                        .accentColor(Theme.Colors.accent)
                    
                    Text("We'll use this to greet you.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: saveName) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(nameInput.isEmpty ? Theme.Colors.inactive : Theme.Colors.accent)
                            .cornerRadius(14)
                    }
                    .disabled(nameInput.isEmpty)
                    
                    Button("Skip for now") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    
                    Button("Don't ask again") {
                        userManager.setDoNotAskAgain(true)
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.7))
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            if let suggested = userManager.getSuggestedName().isEmpty ? nil : userManager.getSuggestedName() {
                nameInput = suggested
            }
        }
    }
    
    private func saveName() {
        userManager.setUserName(nameInput)
        dismiss()
    }
}

#Preview {
    NameOnboardingView(userManager: UserManager.shared)
}
