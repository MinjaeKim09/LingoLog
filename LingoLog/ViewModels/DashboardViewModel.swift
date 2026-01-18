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
    private let studyHistoryManager: StudyHistoryManager
    private var cancellables = Set<AnyCancellable>()
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        studyHistoryManager: StudyHistoryManager = .shared
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.studyHistoryManager = studyHistoryManager
        
        bind()
        refresh()
    }
    
    func refresh() {
        updateCounts(words: wordRepository.words)
        learningStreak = studyHistoryManager.getCurrentStreak()
        updateNotificationTime()
    }
    
    private func bind() {
        wordRepository.$words
            .sink { [weak self] words in
                self?.updateCounts(words: words)
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
        wordsDueForReview = wordRepository.dueWords().count
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
