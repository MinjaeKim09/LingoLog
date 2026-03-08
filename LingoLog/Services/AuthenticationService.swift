import Foundation
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import os

// MARK: - Auth Types

enum AuthProvider: String, Codable {
    case apple
    case google
    case anonymous
}

struct AuthResult {
    let userID: String
    let email: String?
    let displayName: String?
    let provider: AuthProvider
}

// MARK: - Authentication Service

@MainActor
final class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LingoLog", category: "auth")
    
    // Store the current nonce for Apple Sign In verification
    private var currentNonce: String?
    
    // Google Client ID from GoogleService-Info.plist
    private let googleClientID = "407621375642-u8fvah3g0ke22iroe55t1pa1k9fetqa7.apps.googleusercontent.com"
    
    private init() {}
    
    // MARK: - Apple Sign In
    
    /// Generate a random nonce for Apple Sign In
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    /// Get the SHA256 hash of the nonce for Apple Sign In request
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Handle Apple Sign In completion
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> AuthResult? {
        isAuthenticating = true
        authError = nil
        
        switch result {
        case .success(let authorization):
            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Invalid Apple credential."
                isAuthenticating = false
                return nil
            }
            
            guard let identityToken = appleCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                authError = "Unable to fetch identity token."
                isAuthenticating = false
                return nil
            }
            
            let userID = appleCredential.user
            let email = appleCredential.email
            let fullName = [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let displayName = fullName.isEmpty ? nil : fullName
            
            logger.info("Apple Sign In successful for user: \(userID, privacy: .private)")
            
            // Store the identity token for Firebase auth if needed later
            UserDefaults.standard.set(tokenString, forKey: "appleIdentityToken")
            
            let authResult = AuthResult(
                userID: userID,
                email: email,
                displayName: displayName,
                provider: .apple
            )
            
            isAuthenticating = false
            return authResult
            
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                logger.info("Apple Sign In cancelled by user.")
            } else {
                authError = error.localizedDescription
                logger.error("Apple Sign In failed: \(error.localizedDescription, privacy: .public)")
            }
            isAuthenticating = false
            return nil
        }
    }
    
    /// Sign in as guest (anonymous)
    func signInAnonymously() -> AuthResult {
        isAuthenticating = true
        authError = nil
        
        let guestID = UserDefaults.standard.string(forKey: "guestUserID") ?? UUID().uuidString
        UserDefaults.standard.set(guestID, forKey: "guestUserID")
        
        logger.info("Anonymous sign in successful.")
        isAuthenticating = false
        
        return AuthResult(
            userID: guestID,
            email: nil,
            displayName: nil,
            provider: .anonymous
        )
    }
    
    // MARK: - Google Sign In
    
    /// Handle Google Sign In
    func signInWithGoogle(presenting rootViewController: UIViewController) async -> AuthResult? {
        isAuthenticating = true
        authError = nil
        
        do {
            let config = GIDConfiguration(clientID: googleClientID)
            GIDSignIn.sharedInstance.configuration = config
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            
            let userID = user.userID ?? UUID().uuidString
            let email = user.profile?.email
            let displayName = user.profile?.name
            
            // Note: If using Firebase Auth later, you would pass user.idToken?.tokenString
            // and user.accessToken.tokenString here.
            
            logger.info("Google Sign In successful for user: \(userID, privacy: .private)")
            
            let authResult = AuthResult(
                userID: userID,
                email: email,
                displayName: displayName,
                provider: .google
            )
            
            isAuthenticating = false
            return authResult
            
        } catch {
            let nsError = error as NSError
            if nsError.domain == kGIDSignInErrorDomain, nsError.code == GIDSignInError.canceled.rawValue {
                logger.info("Google Sign In cancelled by user.")
            } else {
                authError = error.localizedDescription
                logger.error("Google Sign In failed: \(error.localizedDescription, privacy: .public)")
            }
            
            isAuthenticating = false
            return nil
        }
    }
    
    // MARK: - Nonce Generation
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
}
