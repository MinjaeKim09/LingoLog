import Combine
import CoreData
import Foundation

@MainActor
final class StoryRepository: ObservableObject {
    @Published private(set) var stories: [DailyStory] = []
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        refresh()
        observeContextChanges()
    }
    
    func refresh() {
        let request: NSFetchRequest<DailyStory> = DailyStory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStory.date, ascending: false)]
        do {
            stories = try dataManager.viewContext.fetch(request)
        } catch {
            AppLogger.story.error("Error fetching stories: \(error.localizedDescription, privacy: .public)")
            stories = []
        }
    }
    
    // MARK: - Fetch Methods
    
    func fetchTodayStory(language: String) -> DailyStory? {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let request: NSFetchRequest<DailyStory> = DailyStory.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "language == %@", language),
            NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        ])
        request.fetchLimit = 1
        
        do {
            return try dataManager.viewContext.fetch(request).first
        } catch {
            AppLogger.story.error("Error fetching today's story: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    func fetchStoryHistory(language: String? = nil, limit: Int? = nil) -> [DailyStory] {
        let request: NSFetchRequest<DailyStory> = DailyStory.fetchRequest()
        
        if let language = language {
            request.predicate = NSPredicate(format: "language == %@", language)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStory.date, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try dataManager.viewContext.fetch(request)
        } catch {
            AppLogger.story.error("Error fetching story history: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
    
    func stories(for language: String?) -> [DailyStory] {
        guard let language = language, !language.isEmpty else { return stories }
        return stories.filter { $0.language == language }
    }
    
    // MARK: - Create & Update Methods
    
    @discardableResult
    func saveStory(
        title: String,
        content: String,
        language: String,
        wordIDs: [UUID],
        quizQuestions: [StoryQuizQuestion]
    ) -> DailyStory {
        // Encode quiz questions to JSON
        let quizJSON: String
        do {
            let data = try JSONEncoder().encode(quizQuestions)
            quizJSON = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            AppLogger.story.error("Failed to encode quiz questions: \(error.localizedDescription, privacy: .public)")
            quizJSON = "[]"
        }
        
        let story = DailyStory.create(
            in: dataManager.viewContext,
            title: title,
            content: content,
            language: language,
            wordIDs: wordIDs,
            quizJSON: quizJSON
        )
        
        dataManager.save()
        refresh()
        
        return story
    }
    
    func markQuizCompleted(story: DailyStory, score: Int) {
        story.markQuizCompleted(score: score)
        dataManager.save()
        refresh()
    }
    
    func deleteStory(_ story: DailyStory) {
        dataManager.viewContext.delete(story)
        dataManager.save()
        refresh()
    }
    
    // MARK: - Available Languages
    
    func availableLanguages() -> [String] {
        let languages = stories.compactMap { $0.language }
        return Array(Set(languages)).sorted()
    }
    
    // MARK: - Observation
    
    private func observeContextChanges() {
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: dataManager.viewContext
        )
        .sink { [weak self] _ in
            self?.refresh()
        }
        .store(in: &cancellables)
    }
}
