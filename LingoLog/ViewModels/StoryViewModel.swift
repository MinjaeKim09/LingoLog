import Foundation
import SwiftUI

enum StoryViewState: Equatable {
    case home
    case reading
    case quiz
    case history
}

@MainActor
final class StoryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var viewState: StoryViewState = .home
    @Published var currentStory: DailyStory?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedLanguage: String = ""
    
    // Quiz State
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var showingAnswerFeedback: Bool = false
    @Published var isAnswerCorrect: Bool = false
    @Published var quizScore: Int = 0
    @Published var quizCompleted: Bool = false
    
    // MARK: - Dependencies
    
    private let wordRepository: WordRepository
    private let storyRepository: StoryRepository
    private let geminiService: GeminiService
    private let translationService: TranslationService
    
    // MARK: - Computed Properties
    
    var availableLanguages: [String] {
        wordRepository.availableLanguages()
    }
    
    var hasWords: Bool {
        !wordRepository.words.isEmpty
    }
    
    var wordsForSelectedLanguage: [WordEntry] {
        wordRepository.words(for: selectedLanguage)
    }
    
    var hasTodayStory: Bool {
        todayStory != nil
    }
    
    var todayStory: DailyStory? {
        guard !selectedLanguage.isEmpty else { return nil }
        return storyRepository.fetchTodayStory(language: selectedLanguage)
    }

    var storyLanguages: [String] {
        storyRepository.availableLanguages()
    }

    var storyHistory: [DailyStory] {
        storyRepository.fetchStoryHistory(language: selectedLanguage.isEmpty ? nil : selectedLanguage)
    }
    
    var currentQuizQuestion: StoryQuizQuestion? {
        guard let story = currentStory else { return nil }
        let questions = story.quizQuestions
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var totalQuizQuestions: Int {
        currentStory?.quizQuestions.count ?? 0
    }
    
    var isGeminiConfigured: Bool {
        geminiService.isConfigured
    }
    
    // MARK: - Initialization
    
    init(
        wordRepository: WordRepository,
        storyRepository: StoryRepository,
        geminiService: GeminiService = .shared,
        translationService: TranslationService = .shared
    ) {
        self.wordRepository = wordRepository
        self.storyRepository = storyRepository
        self.geminiService = geminiService
        self.translationService = translationService
        
        // Set default language to first available
        if let firstLanguage = wordRepository.availableLanguages().first {
            selectedLanguage = firstLanguage
        }
    }
    
    // MARK: - Navigation
    
    func navigateTo(_ state: StoryViewState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewState = state
        }
    }
    
    func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch viewState {
            case .home:
                break
            case .reading:
                viewState = .home
            case .quiz:
                viewState = .reading
            case .history:
                viewState = .home
            }
        }
    }
    
    // MARK: - Story Generation
    
    func loadOrGenerateStory() async {
        guard !selectedLanguage.isEmpty else {
            error = "Please select a language first."
            return
        }
        
        // Check if today's story already exists
        if let existingStory = storyRepository.fetchTodayStory(language: selectedLanguage) {
            currentStory = existingStory
            navigateTo(.reading)
            return
        }
        
        // Generate new story
        await generateNewStory()
    }
    
    func generateNewStory() async {
        guard !selectedLanguage.isEmpty else {
            error = "Please select a language first."
            return
        }
        
        let words = wordsForSelectedLanguage
        guard words.count >= 3 else {
            error = "You need at least 3 words in \(selectedLanguage) to generate a story."
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Select 5-8 random words for the story
            let wordCount = min(max(5, words.count), 8)
            let selectedWords = Array(words.shuffled().prefix(wordCount))
            
            // Get language name for the prompt
            let languageName = getLanguageName(for: selectedLanguage)
            
            // Generate story using Gemini
            let response = try await geminiService.generateStory(
                words: selectedWords,
                language: selectedLanguage,
                languageName: languageName
            )
            
            // Save the story
            let wordIDs = selectedWords.compactMap { $0.id }
            let story = storyRepository.saveStory(
                title: response.title,
                content: response.story,
                language: selectedLanguage,
                wordIDs: wordIDs,
                quizQuestions: response.questions
            )
            
            currentStory = story
            isLoading = false
            navigateTo(.reading)
            
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            AppLogger.story.error("Failed to generate story: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func getLanguageName(for code: String) -> String {
        // Try to get from cached languages
        if let language = translationService.cachedLanguages.first(where: { $0.code == code }) {
            return language.name
        }
        
        // Fallback: Use Locale to get language name
        let locale = Locale(identifier: "en")
        if let name = locale.localizedString(forLanguageCode: code) {
            return name
        }
        
        return code
    }
    
    // MARK: - Story Selection
    
    func selectStory(_ story: DailyStory) {
        currentStory = story
        resetQuizState()
        navigateTo(.reading)
    }
    
    // MARK: - Quiz Management
    
    func startQuiz() {
        resetQuizState()
        navigateTo(.quiz)
    }
    
    func resetQuizState() {
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        showingAnswerFeedback = false
        isAnswerCorrect = false
        quizScore = 0
        quizCompleted = false
    }
    
    func selectAnswer(_ index: Int) {
        guard !showingAnswerFeedback else { return }
        guard let question = currentQuizQuestion else { return }
        
        selectedAnswerIndex = index
        isAnswerCorrect = index == question.correctIndex
        
        if isAnswerCorrect {
            quizScore += 1
        }
        
        showingAnswerFeedback = true
    }
    
    func moveToNextQuestion() {
        let totalQuestions = currentStory?.quizQuestions.count ?? 0
        
        if currentQuestionIndex + 1 >= totalQuestions {
            // Quiz completed
            quizCompleted = true
            
            // Save the quiz result
            if let story = currentStory {
                storyRepository.markQuizCompleted(story: story, score: quizScore)
            }
        } else {
            // Move to next question
            withAnimation {
                currentQuestionIndex += 1
                selectedAnswerIndex = nil
                showingAnswerFeedback = false
                isAnswerCorrect = false
            }
        }
    }
    
    func retakeQuiz() {
        resetQuizState()
    }
    
    func finishQuiz() {
        resetQuizState()
        navigateTo(.home)
    }
    
    // MARK: - Words for Current Story
    
    func wordsUsedInStory() -> [WordEntry] {
        guard let story = currentStory else { return [] }
        let wordIDs = story.wordIDs
        return wordRepository.words.filter { word in
            guard let id = word.id else { return false }
            return wordIDs.contains(id)
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
}
