import Foundation
import SwiftUI

@MainActor
final class QuizSessionViewModel: ObservableObject {
    @Published private(set) var wordsDueForReview: [WordEntry] = []
    @Published private(set) var currentWordIndex: Int = 0
    @Published var showingAnswer: Bool = false
    @Published var userAnswer: String = ""
    @Published var isCorrect: Bool = false
    @Published private(set) var quizCompleted: Bool = false
    @Published private(set) var correctAnswers: Int = 0
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var noWordsToRetake: Bool = false
    @Published var showFeedbackOverlay: Bool = false
    @Published var feedbackColor: Color = .clear
    @Published var feedbackIcon: String = ""
    @Published var wordToEdit: WordEntry?
    
    private let wordRepository: WordRepository
    let dataManager: DataManager
    private let studyHistoryManager: StudyHistoryManager
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        studyHistoryManager: StudyHistoryManager = .shared
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.studyHistoryManager = studyHistoryManager
    }
    
    var currentWord: WordEntry? {
        guard currentWordIndex < wordsDueForReview.count else { return nil }
        return wordsDueForReview[currentWordIndex]
    }
    
    func loadWordsForQuiz() {
        wordsDueForReview = wordRepository.dueWords()
        totalQuestions = wordsDueForReview.count
        currentWordIndex = 0
        correctAnswers = 0
        noWordsToRetake = false
        quizCompleted = wordsDueForReview.isEmpty
        showingAnswer = false
        userAnswer = ""
        isCorrect = false
    }
    
    func handleAnswerWithFeedback() {
        guard let word = currentWord else { return }
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let isAnswerCorrect = trimmedAnswer.lowercased() == (word.translation ?? "").lowercased()
        isCorrect = isAnswerCorrect
        
        if isAnswerCorrect {
            correctAnswers += 1
            studyHistoryManager.recordStudySession()
        }
        
        word.updateMasteryLevel(correct: isAnswerCorrect)
        dataManager.save()
        
        feedbackColor = isAnswerCorrect ? Theme.Colors.success : Theme.Colors.error
        feedbackIcon = isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
        showFeedbackOverlay = true
        
        if isAnswerCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                withAnimation {
                    self?.showFeedbackOverlay = false
                }
                self?.moveToNextWord()
            }
        } else {
            showingAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                withAnimation {
                    self?.showFeedbackOverlay = false
                }
            }
        }
    }
    
    func moveToNextWord() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingAnswer = false
            userAnswer = ""
            currentWordIndex += 1
            if currentWordIndex >= wordsDueForReview.count {
                quizCompleted = true
            }
        }
    }
    
    func retakeQuiz() {
        let newWords = wordRepository.dueWords()
        if newWords.isEmpty {
            noWordsToRetake = true
            quizCompleted = true
        } else {
            noWordsToRetake = false
            loadWordsForQuiz()
        }
    }
}
