import Foundation
import SwiftUI

/// A local-only profile. LingoLog does not create or sync user accounts in v1.
@MainActor
final class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: Keys.displayName)
        }
    }

    private enum Keys {
        static let displayName = "user_display_name"
        static let onboardingCompleted = "onboarding_completed"
        static let legacyKeys = [
            "user_email", "user_id", "auth_provider", "auth_state_type", "guestUserID",
            "appleIdentityToken", "user_name", "onboarding_do_not_ask_name"
        ]
    }

    @AppStorage(Keys.onboardingCompleted) var onboardingCompleted: Bool = false

    private init() {
        displayName = UserDefaults.standard.string(forKey: Keys.displayName) ?? ""
        removeLegacyAuthenticationData()
    }

    func resetProfile() {
        displayName = ""
        onboardingCompleted = false
        UserDefaults.standard.removeObject(forKey: Keys.displayName)
        removeLegacyAuthenticationData()
    }

    private func removeLegacyAuthenticationData() {
        for key in Keys.legacyKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
