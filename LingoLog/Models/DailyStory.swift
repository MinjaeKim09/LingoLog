import Foundation
import CoreData

extension DailyStory {
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        content: String,
        language: String,
        wordIDs: [UUID],
        quizJSON: String
    ) -> DailyStory {
        let story = DailyStory(context: context)
        story.id = UUID()
        story.date = Calendar.current.startOfDay(for: Date())
        story.title = title
        story.content = content
        story.language = language
        story.wordIDs = wordIDs
        story.quizJSON = quizJSON
        story.quizCompleted = false
        story.quizScore = 0
        return story
    }
    
    // MARK: - Word IDs Conversion
    
    var wordIDs: [UUID] {
        get {
            guard let data = wordIDsData else { return [] }
            do {
                return try JSONDecoder().decode([UUID].self, from: data)
            } catch {
                AppLogger.story.error("Failed to decode wordIDs: \(error.localizedDescription, privacy: .public)")
                return []
            }
        }
        set {
            do {
                wordIDsData = try JSONEncoder().encode(newValue)
            } catch {
                AppLogger.story.error("Failed to encode wordIDs: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Quiz Questions
    
    var quizQuestions: [StoryQuizQuestion] {
        get {
            guard let json = quizJSON, let data = json.data(using: .utf8) else { return [] }
            do {
                return try JSONDecoder().decode([StoryQuizQuestion].self, from: data)
            } catch {
                AppLogger.story.error("Failed to decode quiz questions: \(error.localizedDescription, privacy: .public)")
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                quizJSON = String(data: data, encoding: .utf8)
            } catch {
                AppLogger.story.error("Failed to encode quiz questions: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    var isToday: Bool {
        guard let storyDate = date else { return false }
        return Calendar.current.isDateInToday(storyDate)
    }
    
    var formattedDate: String {
        guard let storyDate = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: storyDate)
    }
    
    // MARK: - Quiz Management
    
    func markQuizCompleted(score: Int) {
        quizCompleted = true
        quizScore = Int16(score)
    }
}
