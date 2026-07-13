import Combine
import Foundation

@MainActor
final class QuizHomeViewModel: ObservableObject {
    @Published private(set) var wordsDue: [WordEntry] = []
    @Published private(set) var nextReviewDate: Date?
    @Published private(set) var timeRemaining: String = ""
    
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
        let dueWords = wordRepository.dueWords(
            for: languageSpaceManager.activeSpace?.learningLanguageCode
        )
        wordsDue = dueWords
        
        let unmastered = wordRepository.words(
            for: languageSpaceManager.activeSpace?.learningLanguageCode
        ).filter { !$0.isMastered && $0.nextReviewDate != nil }
        nextReviewDate = unmastered.compactMap { $0.nextReviewDate }.min()
        updateTimer()
    }
    
    func updateTimer() {
        guard let targetDate = nextReviewDate else {
            timeRemaining = ""
            return
        }
        
        let now = Date()
        let diff = targetDate.timeIntervalSince(now)
        
        if diff <= 0 {
            timeRemaining = "Ready!"
        } else {
            let hours = Int(diff) / 3600
            let minutes = (Int(diff) % 3600) / 60
            let seconds = Int(diff) % 60
            timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    private func bind() {
        wordRepository.$words
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        languageSpaceManager.$activeSpaceID
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
}
