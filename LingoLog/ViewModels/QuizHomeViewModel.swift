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
    
    func refresh(referenceDate: Date = Date()) {
        update(
            words: wordRepository.words,
            spaceID: languageSpaceManager.activeSpaceID,
            referenceDate: referenceDate
        )
    }

    func updateTimer(referenceDate: Date = Date()) {
        // Due membership must advance with the clock as well as the label.
        refresh(referenceDate: referenceDate)
    }

    private func update(words: [WordEntry], spaceID: UUID?, referenceDate: Date) {
        let language = languageSpaceManager.spaces.first { $0.id == spaceID }?.learningLanguageCode
        let unmastered = words.filter {
            (language == nil || $0.language == language) && !$0.isMastered
        }
        wordsDue = unmastered.filter {
            ($0.nextReviewDate ?? .distantPast) <= referenceDate
        }.sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
        nextReviewDate = unmastered.compactMap { $0.nextReviewDate }.min()

        guard let targetDate = nextReviewDate else {
            timeRemaining = ""
            return
        }
        
        let diff = targetDate.timeIntervalSince(referenceDate)
        
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
            .combineLatest(languageSpaceManager.$activeSpaceID)
            .sink { [weak self] words, spaceID in
                self?.update(words: words, spaceID: spaceID, referenceDate: Date())
            }
            .store(in: &cancellables)
    }
}
