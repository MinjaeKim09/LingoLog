import SwiftUI
import Combine
import UIKit

struct QuizView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isModal: Bool = false
    
    // Note: Removed logoGradient in favor of Theme colors
    
    @State private var wordsDueForReview: [WordEntry] = []
    @State private var currentWordIndex = 0
    @State private var showingAnswer = false
    @State private var userAnswer = ""
    @State private var isCorrect = false
    @State private var showingResult = false
    @State private var quizCompleted = false
    @State private var correctAnswers = 0
    @State private var totalQuestions = 0
    @State private var noWordsToRetake = false
    @Namespace private var animation
    @State private var animateCard = false
    @State private var showFeedbackOverlay = false
    @State private var feedbackColor: Color = .clear
    @State private var feedbackIcon: String = ""
    
    var currentWord: WordEntry? {
        guard currentWordIndex < wordsDueForReview.count else { return nil }
        return wordsDueForReview[currentWordIndex]
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            NavigationView {
                ZStack {
                    if quizCompleted {
                        QuizResultView(
                            correctAnswers: correctAnswers,
                            totalQuestions: totalQuestions,
                            onDismiss: { dismiss() },
                            onRetake: retakeQuiz,
                            noWordsToRetake: noWordsToRetake
                        )
                        .transition(.opacity)
                    } else if let word = currentWord {
                        QuizQuestionCardView(
                            word: word,
                            questionIndex: currentWordIndex + 1,
                            totalQuestions: totalQuestions,
                            showingAnswer: $showingAnswer,
                            userAnswer: $userAnswer,
                            isCorrect: $isCorrect,
                            onAnswerSubmitted: { handleAnswerWithFeedback() }
                        )
                        .matchedGeometryEffect(id: "card", in: animation)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .animation(.easeInOut, value: currentWordIndex)
                    } else {
                        NoWordsView()
                            .transition(.opacity)
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Only show Close button if presented modally
                    if isModal {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { dismiss() }
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                }
                .onAppear {
                    loadWordsForQuiz()
                    // Detect if presented modally (sheet or fullScreenCover)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = scene.windows.first?.rootViewController {
                        var vc = root.presentedViewController
                        while let presented = vc?.presentedViewController { vc = presented }
                        isModal = vc != nil
                    }
                }
            }
            .navigationViewStyle(.stack)
            .edgesIgnoringSafeArea(.all)
            // --- FEEDBACK OVERLAY ---
            // Always render, animate opacity
            Group {
                feedbackColor
                    .ignoresSafeArea()
                    .opacity(showFeedbackOverlay ? 0.3 : 0.0)
                    .animation(.easeInOut(duration: 0.18), value: showFeedbackOverlay)
                VStack {
                    Spacer()
                    Image(systemName: feedbackIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(Color.white)
                        .shadow(radius: 10)
                        .scaleEffect(showFeedbackOverlay ? 1.0 : 0.5)
                        .opacity(showFeedbackOverlay ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showFeedbackOverlay)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            // --- END FEEDBACK OVERLAY ---
        }
    }
    
    private func loadWordsForQuiz() {
        wordsDueForReview = dataManager.fetchWordsDueForReview()
        totalQuestions = wordsDueForReview.count
        currentWordIndex = 0
        correctAnswers = 0
        quizCompleted = wordsDueForReview.isEmpty
        showingAnswer = false
        showingResult = false
        userAnswer = ""
        isCorrect = false
    }
    
    private func handleAnswerWithFeedback() {
        guard let word = currentWord else { return }
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let isAnswerCorrect = trimmedAnswer.lowercased() == (word.translation ?? "").lowercased()
        isCorrect = isAnswerCorrect
        if isAnswerCorrect {
            correctAnswers += 1
        }
        // Update word mastery level
        word.updateMasteryLevel(correct: isAnswerCorrect)
        dataManager.save()
        // Feedback overlay
        feedbackColor = isAnswerCorrect ? Theme.Colors.success : Theme.Colors.error
        feedbackIcon = isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
        // Only show overlay for correct answers
        showFeedbackOverlay = isAnswerCorrect
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        if isAnswerCorrect {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.error)
        }
        // Show correct answer if wrong, then proceed
        if !isAnswerCorrect {
            showingAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    showFeedbackOverlay = false
                }
                showingResult = false
                showingAnswer = false
                userAnswer = ""
                currentWordIndex += 1
                if currentWordIndex >= wordsDueForReview.count {
                    quizCompleted = true
                }
            }
        } else {
            // Hide overlay after short delay, then proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation {
                    showFeedbackOverlay = false
                }
                showingResult = false
                showingAnswer = false
                userAnswer = ""
                currentWordIndex += 1
                if currentWordIndex >= wordsDueForReview.count {
                    quizCompleted = true
                }
            }
        }
    }
    
    private func retakeQuiz() {
        let newWords = dataManager.fetchWordsDueForReview()
        if newWords.isEmpty {
            noWordsToRetake = true
            quizCompleted = true
        } else {
            noWordsToRetake = false
            loadWordsForQuiz()
        }
    }
}

struct QuizQuestionCardView: View {
    let word: WordEntry
    let questionIndex: Int
    let totalQuestions: Int
    @Binding var showingAnswer: Bool
    @Binding var userAnswer: String
    @Binding var isCorrect: Bool
    let onAnswerSubmitted: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: Double(questionIndex), total: Double(max(totalQuestions, 1)))
                    .accentColor(Theme.Colors.accent)
                    .padding(.top, 32)
                HStack {
                    Theme.Typography.body("Question \(questionIndex) of \(totalQuestions)")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index < Int(word.masteryLevel) ? Theme.Colors.success : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            Spacer(minLength: 0)
            // Card
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Theme.Typography.body("Translate this word:")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Theme.Typography.display(word.word ?? "")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if let context = word.context, !context.isEmpty {
                        Theme.Typography.body("Context: \(context)")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .italic()
                            .multilineTextAlignment(.center)
                    }
                    
                    Text(word.language ?? "")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.secondaryAccent.opacity(0.1))
                        .foregroundColor(Theme.Colors.secondaryAccent)
                        .cornerRadius(12)
                }
                .padding(.top, 16)
                
                // Answer
                VStack(spacing: 16) {
                    TextField("Type your answer", text: $userAnswer)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .padding(16)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(16)
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
                        )
                        .disabled(showingAnswer)
                        .onSubmit {
                            if !userAnswer.isEmpty {
                                onAnswerSubmitted()
                            }
                        }
                    
                    if showingAnswer {
                        HStack(spacing: 8) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? Theme.Colors.success : Theme.Colors.error)
                            Text(isCorrect ? "Correct!" : "Correct answer: \(word.translation ?? "")")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(isCorrect ? Theme.Colors.success : Theme.Colors.error)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Button(action: {
                        if !userAnswer.isEmpty {
                            onAnswerSubmitted()
                        }
                    }) {
                        Text("Submit")
                    }
                    .primaryButtonStyle()
                    .disabled(userAnswer.isEmpty)
                    .opacity(userAnswer.isEmpty ? 0.6 : 1.0)
                }
            }
            .padding(32)
            .glassCard()
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

struct QuizResultView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let onDismiss: () -> Void
    let onRetake: () -> Void
    let noWordsToRetake: Bool
    
    private var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    private var message: String {
        if noWordsToRetake {
            return "No words are due for review right now. Please add or wait for more words to become due."
        } else if percentage >= 80 {
            return "Excellent! You're making great progress!"
        } else if percentage >= 60 {
            return "Good job! Keep practicing!"
        } else {
            return "Keep studying! You'll get better with practice."
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: noWordsToRetake ? "checkmark.circle.fill" : (percentage >= 80 ? "star.fill" : "book.fill"))
                .font(.system(size: 60))
                .foregroundColor(noWordsToRetake ? Theme.Colors.success : (percentage >= 80 ? .yellow : Theme.Colors.secondaryAccent))
            
            VStack(spacing: 16) {
                Theme.Typography.display(noWordsToRetake ? "No Words to Retake" : "Quiz Complete!")
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Theme.Typography.body(message)
                    .font(.title3)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !noWordsToRetake {
                VStack(spacing: 8) {
                    Theme.Typography.title("\(correctAnswers) out of \(totalQuestions) correct")
                        .fontWeight(.semibold)
                    
                    Text("\(Int(percentage))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(percentage >= 80 ? Theme.Colors.success : Theme.Colors.secondaryAccent)
                }
                
                Button(action: onRetake) {
                    Text("Retake Quiz")
                }
                .primaryButtonStyle()
            }
            
            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .glassCard()
        .padding()
    }
}

struct NoWordsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.success)
            
            Theme.Typography.title("No words due for review!")
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Theme.Typography.body("Great job! All your words are up to date. Add some new words to start learning.")
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .glassCard()
        .padding()
    }
}

#Preview {
    QuizView()
} 