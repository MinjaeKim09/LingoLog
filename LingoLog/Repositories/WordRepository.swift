import Combine
import CoreData
import Foundation

@MainActor
final class WordRepository: ObservableObject {
    @Published private(set) var words: [WordEntry] = []
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        refresh()
        observeContextChanges()
    }
    
    func refresh() {
        let request: NSFetchRequest<WordEntry> = WordEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordEntry.dateAdded, ascending: false)]
        do {
            words = try dataManager.viewContext.fetch(request)
        } catch {
            AppLogger.data.error("Error fetching words: \(error.localizedDescription, privacy: .public)")
            words = []
        }
    }
    
    func words(for language: String?) -> [WordEntry] {
        guard let language, !language.isEmpty else { return words }
        return words.filter { $0.language == language }
    }
    
    func dueWords(referenceDate: Date = Date()) -> [WordEntry] {
        words.filter { word in
            guard !word.isMastered else { return false }
            guard let nextReviewDate = word.nextReviewDate else { return true }
            return nextReviewDate <= referenceDate
        }.sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
    }
    
    func availableLanguages() -> [String] {
        let languages = words.compactMap { $0.language }
        return Array(Set(languages)).sorted()
    }
    
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
