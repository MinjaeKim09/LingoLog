import Foundation
import SwiftUI
import UIKit
import os

// MARK: - Auth State

enum AuthState: Equatable {
    case unauthenticated
    case guest
    case signedIn(provider: AuthProvider)
    
    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
    
    var isGuest: Bool {
        self == .guest
    }
}

// MARK: - User Manager

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // MARK: - Published Properties
    
    @Published var authState: AuthState = .unauthenticated
    @Published var displayName: String = "" {
        didSet {
            UserDefaults.standard.set(displayName, forKey: Keys.displayName)
        }
    }
    @Published var userEmail: String? = nil
    @Published var userID: String? = nil
    @Published var authProvider: AuthProvider? = nil
    
    @AppStorage("onboarding_completed") var onboardingCompleted: Bool = false
    
    // MARK: - Backward Compat
    
    var userName: String {
        get { displayName }
        set { displayName = newValue }
    }
    
    var shouldShowOnboarding: Bool {
        return !onboardingCompleted
    }
    
    var isAuthenticated: Bool {
        authState.isSignedIn
    }
    
    var isGuest: Bool {
        authState.isGuest
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let displayName = "user_display_name"
        static let userEmail = "user_email"
        static let userID = "user_id"
        static let authProvider = "auth_provider"
        static let authState = "auth_state_type"
    }
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LingoLog", category: "user")
    
    // MARK: - Init
    
    private init() {
        loadPersistedAuth()
    }
    
    // MARK: - Auth Actions
    
    func handleAuthResult(_ result: AuthResult) {
        userID = result.userID
        userEmail = result.email
        authProvider = result.provider
        
        switch result.provider {
        case .apple, .google:
            if let name = result.displayName, !name.isEmpty {
                displayName = name
            }
            authState = .signedIn(provider: result.provider)
            
        case .anonymous:
            authState = .guest
        }
        
        onboardingCompleted = true
        persistAuth()
        
        logger.info("Auth state updated: \(String(describing: self.authState))")
    }
    
    func signOut() {
        authState = .guest
        userEmail = nil
        authProvider = .anonymous
        // Keep displayName and userID for guest mode
        persistAuth()
        logger.info("User signed out, now in guest mode.")
    }
    
    func deleteAccount() {
        // Clear all auth data
        authState = .unauthenticated
        displayName = ""
        userEmail = nil
        userID = nil
        authProvider = nil
        onboardingCompleted = false
        
        clearPersistedAuth()
        logger.info("Account deleted.")
    }
    
    // MARK: - Legacy Methods (backward compat)
    
    func setUserName(_ name: String) {
        displayName = name
    }
    
    func setDoNotAskAgain(_ value: Bool) {
        // Legacy — now handled by onboardingCompleted
        onboardingCompleted = value
    }
    
    func getSuggestedName() -> String {
        return extractName(from: UIDevice.current.name) ?? ""
    }
    
    func reset() {
        displayName = ""
        userEmail = nil
        userID = nil
        authProvider = nil
        authState = .unauthenticated
        onboardingCompleted = false
        clearPersistedAuth()
    }
    
    // MARK: - Persistence
    
    private func persistAuth() {
        UserDefaults.standard.set(displayName, forKey: Keys.displayName)
        UserDefaults.standard.set(userEmail, forKey: Keys.userEmail)
        UserDefaults.standard.set(userID, forKey: Keys.userID)
        UserDefaults.standard.set(authProvider?.rawValue, forKey: Keys.authProvider)
        
        let stateString: String
        switch authState {
        case .unauthenticated: stateString = "unauthenticated"
        case .guest: stateString = "guest"
        case .signedIn: stateString = "signedIn"
        }
        UserDefaults.standard.set(stateString, forKey: Keys.authState)
    }
    
    private func loadPersistedAuth() {
        displayName = UserDefaults.standard.string(forKey: Keys.displayName) ?? ""
        userEmail = UserDefaults.standard.string(forKey: Keys.userEmail)
        userID = UserDefaults.standard.string(forKey: Keys.userID)
        
        if let providerRaw = UserDefaults.standard.string(forKey: Keys.authProvider) {
            authProvider = AuthProvider(rawValue: providerRaw)
        }
        
        let stateString = UserDefaults.standard.string(forKey: Keys.authState) ?? "unauthenticated"
        switch stateString {
        case "guest":
            authState = .guest
        case "signedIn":
            if let provider = authProvider {
                authState = .signedIn(provider: provider)
            } else {
                authState = .guest
            }
        default:
            // Check legacy migration: if old userName exists, migrate to guest
            if let legacyName = UserDefaults.standard.string(forKey: "user_name"), !legacyName.isEmpty {
                displayName = legacyName
                authState = .guest
                onboardingCompleted = true
                persistAuth()
                // Clean up legacy key
                UserDefaults.standard.removeObject(forKey: "user_name")
                logger.info("Migrated legacy user to guest mode.")
            } else if onboardingCompleted {
                authState = .guest
            } else {
                authState = .unauthenticated
            }
        }
    }
    
    private func clearPersistedAuth() {
        for key in [Keys.displayName, Keys.userEmail, Keys.userID, Keys.authProvider, Keys.authState] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        // Also clear legacy key
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.removeObject(forKey: "onboarding_do_not_ask_name")
    }
    
    // MARK: - Helpers
    
    private func extractName(from deviceName: String) -> String? {
        let pattern = "^(.*?)(?:'s|'S)\\s+(?:iPhone|iPad|iPod|Device|MacBook|Watch)$"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: deviceName.utf16.count)
            
            if let match = regex.firstMatch(in: deviceName, options: [], range: range) {
                if let nameRange = Range(match.range(at: 1), in: deviceName) {
                    let name = String(deviceName[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return name.isEmpty ? nil : name
                }
            }
        } catch {
            logger.error("Regex error: \(error.localizedDescription, privacy: .public)")
        }
        
        return nil
    }
}
