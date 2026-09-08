import Foundation

/// Version the keys when the disclosed data use changes.
enum CloudConsent {
    static let translationKey = "cloudTranslationConsent.v1"
    static let storiesKey = "geminiStoriesConsent.v1"

    static func require(_ key: String) throws {
        guard UserDefaults.standard.bool(forKey: key) else {
            throw ConsentRequired()
        }
    }

    struct ConsentRequired: LocalizedError {
        var errorDescription: String? {
            "Allow this online feature before sending your words. You can change your choice in More."
        }
    }
}
