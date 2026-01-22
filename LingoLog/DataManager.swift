import CoreData
import Foundation

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var notificationHour: Int {
        didSet { saveNotificationTime() }
    }
    @Published var notificationMinute: Int {
        didSet { saveNotificationTime() }
    }
    
    private let notificationHourKey = "notificationHour"
    private let notificationMinuteKey = "notificationMinute"
    
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "LingoLog")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                AppLogger.data.error("Core Data failed to load: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Load notification time from UserDefaults or default to 9:00
        if UserDefaults.standard.object(forKey: notificationHourKey) != nil {
            self.notificationHour = UserDefaults.standard.integer(forKey: notificationHourKey)
        } else {
            self.notificationHour = 9 // Default to 9 AM
        }
        
        if UserDefaults.standard.object(forKey: notificationMinuteKey) != nil {
            self.notificationMinute = UserDefaults.standard.integer(forKey: notificationMinuteKey)
        } else {
            self.notificationMinute = 0 // Default to 0 minutes
        }
    }
    
    private func saveNotificationTime() {
        UserDefaults.standard.set(notificationHour, forKey: notificationHourKey)
        UserDefaults.standard.set(notificationMinute, forKey: notificationMinuteKey)
    }
    
    func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                self.objectWillChange.send()
            } catch {
                AppLogger.data.error("Error saving context: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func addWord(word: String, translation: String, language: String, context: String? = nil) {
        _ = WordEntry.create(in: viewContext, 
                                      word: word, 
                                      translation: translation, 
                                      language: language, 
                                      contextString: context)
        save()
    }
    
    func deleteWord(_ word: WordEntry) {
        viewContext.delete(word)
        save()
    }
    
    func fetchWords(for language: String? = nil) -> [WordEntry] {
        let request: NSFetchRequest<WordEntry> = WordEntry.fetchRequest()
        
        if let language = language {
            request.predicate = NSPredicate(format: "language == %@", language)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WordEntry.dateAdded, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            AppLogger.data.error("Error fetching words: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
    
    func fetchWordsDueForReview() -> [WordEntry] {
        let request: NSFetchRequest<WordEntry> = WordEntry.fetchRequest()
        request.predicate = NSPredicate(format: "isMastered == NO AND (nextReviewDate == nil OR nextReviewDate <= %@)", Date() as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WordEntry.nextReviewDate, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            AppLogger.data.error("Error fetching words due for review: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
    
    func getAvailableLanguages() -> [String] {
        let request = NSFetchRequest<NSDictionary>(entityName: "WordEntry")
        request.propertiesToFetch = ["language"]
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType

        do {
            let results = try viewContext.fetch(request)
            return results.compactMap { $0["language"] as? String }.sorted()
        } catch {
            AppLogger.data.error("Error fetching languages: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
} 