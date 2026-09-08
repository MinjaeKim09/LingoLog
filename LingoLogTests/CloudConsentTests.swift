import Foundation
import Testing
@testable import LingoLog

@Suite(.serialized)
struct CloudConsentTests {
    @Test func translationRejectsBeforeMakingAnUnauthorisedRequest() async {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: CloudConsent.translationKey)
        defer { defaults.set(previous, forKey: CloudConsent.translationKey) }
        defaults.set(false, forKey: CloudConsent.translationKey)
        do {
            _ = try await TranslationService.shared.translate(text: "hello", from: "en", to: "ko")
            Issue.record("Translation proceeded without consent")
        } catch {
            #expect(error is CloudConsent.ConsentRequired)
        }
    }

    @Test func storiesRejectBeforeAttestationOrSubscriptionChecks() async {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: CloudConsent.storiesKey)
        defer { defaults.set(previous, forKey: CloudConsent.storiesKey) }
        defaults.set(false, forKey: CloudConsent.storiesKey)
        do {
            _ = try await GeminiService.shared.generateStory(words: [], language: "ko", languageName: "Korean", subscriptionJWS: nil)
            Issue.record("Story generation proceeded without consent")
        } catch {
            #expect(error is CloudConsent.ConsentRequired)
        }
    }
}
