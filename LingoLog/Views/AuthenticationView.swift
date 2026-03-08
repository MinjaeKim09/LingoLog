import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var userManager: UserManager
    @StateObject private var authService = AuthenticationService.shared
    @State private var currentNonce: String?
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App Branding
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accent.opacity(0.2), Theme.Colors.secondaryAccent.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.secondaryAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 6) {
                        Theme.Typography.display("LingoLog")
                            .foregroundStyle(Theme.Colors.textPrimary)
                        
                        Theme.Typography.body("Your personal vocabulary journal")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: 14) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = authService.generateNonce()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = authService.sha256(nonce)
                    } onCompletion: { result in
                        Task {
                            if let authResult = await authService.handleAppleSignIn(result: result) {
                                userManager.handleAuthResult(authResult)
                                dismiss()
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .cornerRadius(14)
                    
                    // Google Sign In
                    Button(action: {
                        guard let rootViewController = getRootViewController() else {
                            return
                        }
                        
                        Task {
                            if let authResult = await authService.signInWithGoogle(presenting: rootViewController) {
                                userManager.handleAuthResult(authResult)
                                dismiss()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(colorScheme == .dark ? .white : .black)
                        .cornerRadius(14)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Theme.Colors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Rectangle()
                            .fill(Theme.Colors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    // Guest Mode
                    Button(action: {
                        let result = authService.signInAnonymously()
                        userManager.handleAuthResult(result)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.title3)
                            Text("Continue as Guest")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                
                // Loading Overlay
                if authService.isAuthenticating {
                    ProgressView()
                        .tint(Theme.Colors.accent)
                        .scaleEffect(1.2)
                        .padding(.top, 16)
                }
                
                // Error
                if let error = authService.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                    .frame(height: 40)
                
                // Footer
                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }
        }
        .interactiveDismissDisabled(authService.isAuthenticating)
    }
    
    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

#Preview {
    AuthenticationView(userManager: UserManager.shared)
}
