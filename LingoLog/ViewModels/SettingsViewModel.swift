import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    struct LanguageStat: Identifiable {
        let id = UUID()
        let language: String
        let count: Int
    }
    
    @Published private(set) var totalWords: Int = 0
    @Published private(set) var masteredWords: Int = 0
    @Published private(set) var wordsDueForReview: Int = 0
    @Published private(set) var languageStats: [LanguageStat] = []
    
    private let wordRepository: WordRepository
    private let languageSpaceManager: LanguageSpaceManager
    private var cancellables = Set<AnyCancellable>()
    
    init(wordRepository: WordRepository, languageSpaceManager: LanguageSpaceManager) {
        self.wordRepository = wordRepository
        self.languageSpaceManager = languageSpaceManager
        bind()
        refresh()
    }
    
    func refresh() {
        updateStats(words: wordsForActiveSpace)
    }
    
    private func bind() {
        wordRepository.$words
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateStats(words: self.wordsForActiveSpace)
            }
            .store(in: &cancellables)

        languageSpaceManager.$activeSpaceID
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    private func updateStats(words: [WordEntry]) {
        totalWords = words.count
        masteredWords = words.filter { $0.isMastered }.count
        wordsDueForReview = wordRepository.dueWords(
            for: languageSpaceManager.activeSpace?.learningLanguageCode
        ).count
        
        let grouped = Dictionary(grouping: words, by: { $0.language ?? "Unknown" })
        languageStats = grouped
            .map { LanguageStat(language: $0.key, count: $0.value.count) }
            .sorted { $0.language < $1.language }
    }

    private var wordsForActiveSpace: [WordEntry] {
        wordRepository.words(for: languageSpaceManager.activeSpace?.learningLanguageCode)
    }
}
