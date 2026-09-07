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
        updateStats(words: wordRepository.words, spaceID: languageSpaceManager.activeSpaceID)
    }
    
    private func bind() {
        wordRepository.$words
            .combineLatest(languageSpaceManager.$activeSpaceID)
            .sink { [weak self] words, spaceID in
                self?.updateStats(words: words, spaceID: spaceID)
            }
            .store(in: &cancellables)
    }
    
    private func updateStats(words: [WordEntry], spaceID: UUID?) {
        let language = languageSpaceManager.spaces.first { $0.id == spaceID }?.learningLanguageCode
        let words = words.filter { language == nil || $0.language == language }
        totalWords = words.count
        masteredWords = words.filter { $0.isMastered }.count
        wordsDueForReview = words.filter { !$0.isMastered && $0.isDueForReview }.count
        
        let grouped = Dictionary(grouping: words, by: { $0.language ?? "Unknown" })
        languageStats = grouped
            .map { LanguageStat(language: $0.key, count: $0.value.count) }
            .sorted { $0.language < $1.language }
    }

}
