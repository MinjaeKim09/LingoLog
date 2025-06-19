import Foundation
import CoreData

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
            // Set a 24-hour cooldown before next review
            nextReviewDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        } else {
            masteryLevel = max(0, masteryLevel - 1)
            // Make the word immediately due again
            nextReviewDate = Date()
        }
        
        reviewCount += 1
        lastReviewed = Date()
        isMastered = masteryLevel >= 5
    }
    
    var isDueForReview: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return Date() >= nextReview
    }
} 