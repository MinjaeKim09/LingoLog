import Foundation
import CoreData

// MARK: - Value Type for Safe SwiftUI Display
/// A value type snapshot of WordEntry for use in SwiftUI views.
/// This decouples views from Core Data lifecycle (deletion, faulting, etc.)
struct WordDisplayModel: Identifiable, Equatable {
    let objectID: NSManagedObjectID
    /// Stable identity for SwiftUI diffing/animations.
    /// Using `objectID` avoids accidental "new ID" glitches during refreshes.
    var id: NSManagedObjectID { objectID }
    let word: String
    let translation: String
    let language: String
    let context: String?
    let dateAdded: Date?
    let reviewCount: Int32
    let masteryLevel: Int32
    let isMastered: Bool
    let nextReviewDate: Date?
    
    init(from entry: WordEntry) {
        self.objectID = entry.objectID
        self.word = entry.word ?? ""
        self.translation = entry.translation ?? ""
        self.language = entry.language ?? ""
        self.context = entry.context
        self.dateAdded = entry.dateAdded
        self.reviewCount = entry.reviewCount
        self.masteryLevel = entry.masteryLevel
        self.isMastered = entry.isMastered
        self.nextReviewDate = entry.nextReviewDate
    }
}

// MARK: - WordEntry Extension
extension WordEntry {
    static func create(in context: NSManagedObjectContext, 
                      word: String, 
                      translation: String, 
                      language: String, 
                      contextString: String? = nil) -> WordEntry {
        let entry = WordEntry(context: context)
        entry.id = UUID()
        entry.word = word
        entry.translation = translation
        entry.language = language
        entry.context = contextString
        entry.dateAdded = Date()
        entry.reviewCount = 0
        entry.masteryLevel = 0
        entry.isMastered = false
        entry.nextReviewDate = Date() // Start reviewing immediately
        return entry
    }
    
    func updateMasteryLevel(correct: Bool) {
        if correct {
            masteryLevel = min(5, masteryLevel + 1)
            let intervalDays = reviewIntervalDays(for: masteryLevel)
            nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date())
        } else {
            masteryLevel = max(0, masteryLevel - 1)
            // Make the word immediately due again
            nextReviewDate = Date()
        }
        
        reviewCount += 1
        lastReviewed = Date()
        isMastered = masteryLevel >= 5
    }

    private func reviewIntervalDays(for level: Int32) -> Int {
        switch level {
        case 1: return 1
        case 2: return 3
        case 3: return 7
        case 4: return 14
        case 5: return 30
        default: return 1
        }
    }
    
    var isDueForReview: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return Date() >= nextReview
    }
} 