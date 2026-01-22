import Combine
import CoreData
import Foundation

@MainActor
final class WordRepository: ObservableObject {
    /// Raw Core Data objects - use for mutations only
    @Published private(set) var words: [WordEntry] = []
    
    /// Safe value-type snapshots for display in SwiftUI views
    @Published private(set) var displayModels: [WordDisplayModel] = []
    
    /// Flag to suppress notification-driven refresh during explicit operations
    private(set) var isSuppressingRefresh = false
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        refresh()
        observeContextChanges()
    }
    
    /// Enable or disable refresh suppression during explicit operations
    func suppressRefresh(_ suppress: Bool) {
        isSuppressingRefresh = suppress
    }
    
    func refresh() {
        let request: NSFetchRequest<WordEntry> = WordEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordEntry.dateAdded, ascending: false)]
        do {
            // Filter out any deleted objects (isFault is normal lazy-loading, not invalid)
            let fetched = try dataManager.viewContext.fetch(request)
            words = fetched.filter { !$0.isDeleted }
            // Create value-type snapshots for safe SwiftUI rendering
            displayModels = words.map { WordDisplayModel(from: $0) }
        } catch {
            AppLogger.data.error("Error fetching words: \(error.localizedDescription, privacy: .public)")
            words = []
            displayModels = []
        }
    }
    
    /// Get display models filtered by language
    func displayModels(for language: String?) -> [WordDisplayModel] {
        guard let language, !language.isEmpty else { return displayModels }
        return displayModels.filter { $0.language == language }
    }
    
    /// Get the managed object for a given objectID (for mutations like delete)
    func wordEntry(for objectID: NSManagedObjectID) -> WordEntry? {
        words.first { $0.objectID == objectID }
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
        let languages = displayModels.map { $0.language }
        return Array(Set(languages)).sorted()
    }
    
    private func observeContextChanges() {
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: dataManager.viewContext
        )
        // Core Data often emits multiple change notifications for one user action.
        // Debouncing prevents SwiftUI list diffing from "thrashing" mid-gesture.
        .receive(on: RunLoop.main)
        .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            guard let self, !self.isSuppressingRefresh else { return }
            self.refresh()
        }
        .store(in: &cancellables)
    }
}
