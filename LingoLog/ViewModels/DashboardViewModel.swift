import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var totalWords: Int = 0
    @Published private(set) var masteredWords: Int = 0
    @Published private(set) var wordsDueForReview: Int = 0
    @Published private(set) var learningStreak: Int = 0
    @Published private(set) var notificationTimeString: String = ""
    
    private let wordRepository: WordRepository
    private let dataManager: DataManager
    private let languageSpaceManager: LanguageSpaceManager
    private let studyHistoryManager: StudyHistoryManager
    private var cancellables = Set<AnyCancellable>()
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        languageSpaceManager: LanguageSpaceManager,
        studyHistoryManager: StudyHistoryManager = .shared
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.languageSpaceManager = languageSpaceManager
        self.studyHistoryManager = studyHistoryManager
        
        bind()
        refresh()
    }
    
    func refresh() {
        updateCounts(words: wordRepository.words, spaceID: languageSpaceManager.activeSpaceID)
        learningStreak = studyHistoryManager.getCurrentStreak()
        updateNotificationTime()
    }
    
    private func bind() {
        wordRepository.$words
            .combineLatest(languageSpaceManager.$activeSpaceID)
            .sink { [weak self] words, spaceID in
                self?.updateCounts(words: words, spaceID: spaceID)
            }
            .store(in: &cancellables)
        
        dataManager.$notificationHour
            .combineLatest(dataManager.$notificationMinute)
            .sink { [weak self] hour, minute in
                self?.updateNotificationTime(hour: hour, minute: minute)
            }
            .store(in: &cancellables)
    }
    
    private func updateCounts(words: [WordEntry], spaceID: UUID?) {
        let language = languageSpaceManager.spaces.first { $0.id == spaceID }?.learningLanguageCode
        let words = words.filter { language == nil || $0.language == language }
        totalWords = words.count
        masteredWords = words.filter { $0.isMastered }.count
        wordsDueForReview = words.filter { !$0.isMastered && $0.isDueForReview }.count
    }
    
    private func updateNotificationTime() {
        updateNotificationTime(hour: dataManager.notificationHour, minute: dataManager.notificationMinute)
    }

    private func updateNotificationTime(hour: Int, minute: Int) {
        let comps = DateComponents(
            hour: hour,
            minute: minute
        )
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        notificationTimeString = formatter.string(from: date)
    }
}
