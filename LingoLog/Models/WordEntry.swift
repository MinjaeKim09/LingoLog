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