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
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Load notification time from UserDefaults or default to 9:00
        let hour = UserDefaults.standard.integer(forKey: notificationHourKey)
        let minute = UserDefaults.standard.integer(forKey: notificationMinuteKey)
        self.notificationHour = hour == 0 ? 9 : hour
        self.notificationMinute = minute
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
                print("Error saving context: \(error)")
            }
        }
    }
    
    func addWord(word: String, translation: String, language: String, context: String? = nil) {
        let newWord = WordEntry.create(in: viewContext, 
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
            print("Error fetching words: \(error)")
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
            print("Error fetching words due for review: \(error)")
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
            print("Error fetching languages: \(error)")
            return []
        }
    }
} 