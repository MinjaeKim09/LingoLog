import Foundation

/// The app's composition root. Production uses the default services while tests and previews
/// can provide isolated instances without changing global state.
@MainActor
final class AppEnvironment {
    let dataManager: DataManager
    let wordRepository: WordRepository
    let storyRepository: StoryRepository
    let userManager: UserManager
    let translationService: TranslationService
    let storyService: GeminiService
    let storeManager: StoreManager
    let languageSpaceManager: LanguageSpaceManager

    init(
        dataManager: DataManager = .shared,
        userManager: UserManager = .shared,
        translationService: TranslationService = .shared,
        storyService: GeminiService = .shared,
        storeManager: StoreManager = .shared
    ) {
        self.dataManager = dataManager
        self.userManager = userManager
        self.translationService = translationService
        self.storyService = storyService
        self.storeManager = storeManager
        self.languageSpaceManager = LanguageSpaceManager(dataManager: dataManager)
        self.wordRepository = WordRepository(dataManager: dataManager)
        self.storyRepository = StoryRepository(dataManager: dataManager)
    }
}
