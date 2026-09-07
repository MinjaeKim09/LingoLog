import CoreData
import Foundation
import Testing
@testable import LingoLog

@MainActor
struct ViewModelRegressionTests {
    @Test func switchingSpacesUpdatesEveryConsumerImmediately() throws {
        let fixture = try VocabularyFixture()
        let list = WordListViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        let dashboard = DashboardViewModel(
            wordRepository: fixture.words, dataManager: fixture.data, languageSpaceManager: fixture.spaces
        )
        let settings = SettingsViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        let quiz = QuizHomeViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        let add = AddWordViewModel(
            dataManager: fixture.data, translationService: ControlledTranslator(), languageSpaceManager: fixture.spaces
        )
        let story = StoryViewModel(
            wordRepository: fixture.words,
            storyRepository: StoryRepository(dataManager: fixture.data),
            languageSpaceManager: fixture.spaces
        )
        story.viewState = .quiz

        fixture.spaces.setActiveSpace(fixture.japanese)

        #expect(list.filteredWords.map(\.word) == ["猫"])
        #expect(dashboard.totalWords == 1)
        #expect(dashboard.wordsDueForReview == 1)
        #expect(settings.totalWords == 1)
        #expect(settings.languageStats.map(\.language) == ["ja"])
        #expect(quiz.wordsDue.map(\.word) == ["猫"])
        #expect(add.learningLanguage == "ja")
        #expect(story.selectedLanguage == "ja")
        #expect(story.viewState == .home)

        fixture.spaces.setActiveSpace(fixture.korean)
        #expect(list.filteredWords.count == 2)
        #expect(dashboard.totalWords == 2)
        #expect(settings.totalWords == 2)
        #expect(quiz.wordsDue.count == 2)
        #expect(add.learningLanguage == "ko")
        #expect(story.selectedLanguage == "ko")
    }

    @Test func searchUsesTheCurrentQueryAndClearsImmediately() throws {
        let fixture = try VocabularyFixture()
        let list = WordListViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        list.searchText = "friend"
        #expect(list.filteredWords.map(\.word) == ["친구"])
        list.searchText = "school"
        #expect(list.filteredWords.map(\.word) == ["학교"])
        list.searchText = "no match"
        #expect(list.filteredWords.isEmpty)
        list.searchText = ""
        #expect(list.filteredWords.count == 2)
    }

    @Test func repositoryPublishesNewWordsWithoutASecondRefresh() throws {
        let fixture = try VocabularyFixture()
        let list = WordListViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        let dashboard = DashboardViewModel(
            wordRepository: fixture.words, dataManager: fixture.data, languageSpaceManager: fixture.spaces
        )
        let settings = SettingsViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        let quiz = QuizHomeViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        fixture.data.addWord(word: "집", translation: "house", language: "ko")
        fixture.words.refresh()
        #expect(list.filteredWords.count == 3)
        #expect(dashboard.totalWords == 3)
        #expect(settings.totalWords == 3)
        #expect(quiz.wordsDue.count == 3)
    }

    @Test func deletingWordsRefreshesSnapshotsAndCannotResurrectSearchResults() throws {
        let fixture = try VocabularyFixture()
        let list = WordListViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        list.searchText = "friend"
        let deletedID = try #require(list.filteredWords.first?.objectID)
        list.deleteWords(at: IndexSet(integer: 0), dataManager: fixture.data)

        #expect(!fixture.words.words.contains { $0.objectID == deletedID })
        #expect(!fixture.words.displayModels.contains { $0.objectID == deletedID })
        #expect(!fixture.data.fetchWords().contains { $0.objectID == deletedID })
        list.searchText = ""
        #expect(list.filteredWords.map(\.word) == ["학교"])
        list.searchText = "friend"
        #expect(list.filteredWords.isEmpty)
    }

    @Test func reviewDeadlineEnablesPracticeWithoutNavigationOrDataChanges() throws {
        let fixture = try VocabularyFixture()
        fixture.spaces.setActiveSpace(fixture.japanese)
        let word = try #require(fixture.words.words(for: "ja").first)
        let deadline = Date().addingTimeInterval(60)
        word.nextReviewDate = deadline
        let quiz = QuizHomeViewModel(wordRepository: fixture.words, languageSpaceManager: fixture.spaces)
        quiz.updateTimer(referenceDate: deadline.addingTimeInterval(-1))
        #expect(quiz.wordsDue.isEmpty)
        #expect(quiz.timeRemaining == "00:00:01")
        quiz.updateTimer(referenceDate: deadline)
        #expect(quiz.wordsDue.map(\.objectID) == [word.objectID])
        #expect(quiz.timeRemaining == "Ready!")
    }

    @Test func editingInputInvalidatesThePreviousTranslationBeforeDebounce() async throws {
        let fixture = try VocabularyFixture()
        let translator = ControlledTranslator()
        let add = AddWordViewModel(
            dataManager: fixture.data, translationService: translator, languageSpaceManager: fixture.spaces
        )
        add.inputText = "친구"
        try await waitUntil { await translator.requestCount == 1 }
        await translator.complete(0, with: .success("friend"))
        try await waitUntil { add.canSave }

        add.inputText = "학교"
        #expect(add.translation == nil)
        #expect(!add.canSave)
        #expect(!add.saveTranslation())
        #expect(fixture.data.fetchWords().count == 3)
        add.inputText = ""
        #expect(!add.isTranslating)
    }

    @Test func cancelledTranslationCannotOverwriteANewerResult() async throws {
        let fixture = try VocabularyFixture()
        let translator = ControlledTranslator()
        let add = AddWordViewModel(
            dataManager: fixture.data, translationService: translator,
            languageSpaceManager: fixture.spaces, translationDelay: .zero
        )
        add.inputText = "친구"
        try await waitUntil { await translator.requestCount == 1 }
        add.inputText = "학교"
        try await waitUntil { await translator.requestCount == 2 }
        await translator.complete(1, with: .success("school"))
        try await waitUntil { add.translation == "school" }
        await translator.complete(0, with: .success("friend"))
        // Give the resumed, cancelled task a chance to publish its stale result.
        try await Task.sleep(for: .milliseconds(30))
        #expect(add.translation == "school")
        #expect(add.canSave)
        #expect(add.errorMessage == nil)
    }

    @Test func cancelledFailureCannotClearTheNewRequestsLoadingState() async throws {
        let fixture = try VocabularyFixture()
        let translator = ControlledTranslator()
        let add = AddWordViewModel(
            dataManager: fixture.data, translationService: translator,
            languageSpaceManager: fixture.spaces, translationDelay: .zero
        )
        add.inputText = "친구"
        try await waitUntil { await translator.requestCount == 1 }
        fixture.spaces.setActiveSpace(fixture.japanese)
        try await waitUntil { await translator.requestCount == 2 }
        #expect(await translator.sourceLanguage(for: 1) == "ja")
        await translator.complete(0, with: .failure(URLError(.cancelled)))
        try await Task.sleep(for: .milliseconds(30))
        #expect(add.isTranslating)
        #expect(add.errorMessage == nil)
        await translator.complete(1, with: .success("new meaning"))
        try await waitUntil { add.canSave }
        #expect(add.translation == "new meaning")
    }

    @Test func recoveredStoryDecodesItsOriginalVocabulary() throws {
        let response = try JSONDecoder().decode(StoryResponse.self, from: Data("""
        {"title":"A story","story":"Content","questions":[],
         "words":[{"word":"친구","translation":"friend"}]}
        """.utf8))
        #expect(response.words?.first?.term == "친구")
        #expect(response.words?.first?.meaning == "friend")
        let legacy = try JSONDecoder().decode(StoryResponse.self, from: Data("""
        {"title":"A story","story":"Content","questions":[]}
        """.utf8))
        #expect(legacy.words == nil)
    }

    private func waitUntil(_ condition: () async -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while !(await condition()) && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(await condition())
    }
}

@MainActor
private final class VocabularyFixture {
    let data: DataManager
    let words: WordRepository
    let spaces: LanguageSpaceManager
    let korean = LanguageSpace(learningLanguageCode: "ko", meaningLanguageCode: "en")
    let japanese = LanguageSpace(learningLanguageCode: "ja", meaningLanguageCode: "en")
    private let suiteName = "ViewModelRegressionTests.\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        data = DataManager(inMemory: true)
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(try JSONEncoder().encode([korean, japanese]), forKey: "languageSpaces.v1")
        defaults.set(korean.id.uuidString, forKey: "activeLanguageSpaceID.v1")
        spaces = LanguageSpaceManager(dataManager: data, defaults: defaults)
        data.addWord(word: "친구", translation: "friend", language: "ko")
        data.addWord(word: "학교", translation: "school", language: "ko")
        data.addWord(word: "猫", translation: "cat", language: "ja")
        words = WordRepository(dataManager: data)
        #expect(data.viewContext.persistentStoreCoordinator?.persistentStores.first?.type == NSInMemoryStoreType)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

// Deliberately ignores task cancellation so tests exercise late provider responses.
private actor ControlledTranslator: VocabularyTranslating {
    private var requests: [(source: String, continuation: CheckedContinuation<String, Error>?)] = []
    var requestCount: Int { requests.count }

    func translate(text: String, from sourceLang: String, to targetLang: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            requests.append((sourceLang, continuation))
        }
    }

    func sourceLanguage(for index: Int) -> String { requests[index].source }

    func complete(_ index: Int, with result: Result<String, Error>) {
        requests[index].continuation?.resume(with: result)
        requests[index].continuation = nil
    }
}
