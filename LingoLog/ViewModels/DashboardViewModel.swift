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
        updateCounts(words: wordsForActiveSpace)
        learningStreak = studyHistoryManager.getCurrentStreak()
        updateNotificationTime()
    }
    
    private func bind() {
        wordRepository.$words
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateCounts(words: self.wordsForActiveSpace)
            }
            .store(in: &cancellables)

        languageSpaceManager.$activeSpaceID
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
        
        dataManager.$notificationHour
            .merge(with: dataManager.$notificationMinute)
            .sink { [weak self] _ in
                self?.updateNotificationTime()
            }
            .store(in: &cancellables)
    }
    
    private func updateCounts(words: [WordEntry]) {
        totalWords = words.count
        masteredWords = words.filter { $0.isMastered }.count
        wordsDueForReview = wordRepository.dueWords(
            for: languageSpaceManager.activeSpace?.learningLanguageCode
        ).count
    }

    private var wordsForActiveSpace: [WordEntry] {
        wordRepository.words(for: languageSpaceManager.activeSpace?.learningLanguageCode)
    }
    
    private func updateNotificationTime() {
        let comps = DateComponents(
            hour: dataManager.notificationHour,
            minute: dataManager.notificationMinute
        )
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        notificationTimeString = formatter.string(from: date)
    }
}
