import SwiftUI
import Combine
import UIKit

struct QuizView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isModal: Bool = false
    
    // Logo-inspired gradient
    private let logoGradient = LinearGradient(
        colors: [Color.cyan, Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
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
            Color(.systemGray6)
                .ignoresSafeArea()
            NavigationView {
                ZStack {
                    if quizCompleted {
                        QuizResultView(
                            correctAnswers: correctAnswers,
                            totalQuestions: totalQuestions,
                            onDismiss: { dismiss() },
                            onRetake: retakeQuiz,
                            noWordsToRetake: noWordsToRetake,
                            gradient: logoGradient
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
                            onAnswerSubmitted: { handleAnswerWithFeedback() },
                            gradient: logoGradient
                        )
                        .matchedGeometryEffect(id: "card", in: animation)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .animation(.easeInOut, value: currentWordIndex)
                    } else {
                        NoWordsView(gradient: logoGradient)
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
                                .foregroundStyle(logoGradient)
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
                    .opacity(showFeedbackOverlay ? 0.7 : 0.0)
                    .animation(.easeInOut(duration: 0.18), value: showFeedbackOverlay)
                VStack {
                    Spacer()
                    Image(systemName: feedbackIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(logoGradient)
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
        feedbackColor = isAnswerCorrect ? .green : .red
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
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: Double(questionIndex), total: Double(max(totalQuestions, 1)))
                    .accentColor(.blue)
                    .padding(.top, 32)
                HStack {
                    Text("Question \(questionIndex) of \(totalQuestions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index < Int(word.masteryLevel) ? Color.green : Color.gray.opacity(0.3))
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
                    Text("Translate this word:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(word.word ?? "")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    if let context = word.context, !context.isEmpty {
                        Text("Context: \(context)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(.center)
                    }
                    Text("Language: \(word.language ?? "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 16)
                // Answer
                VStack(spacing: 12) {
                    TextField("Type your answer", text: $userAnswer)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .font(.title3)
                        .disabled(showingAnswer)
                        .onSubmit {
                            if !userAnswer.isEmpty {
                                onAnswerSubmitted()
                            }
                        }
                    if showingAnswer {
                        HStack(spacing: 8) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? .green : .red)
                            Text(isCorrect ? "Correct!" : "Correct answer: \(word.translation ?? "")")
                                .foregroundColor(isCorrect ? .green : .red)
                                .fontWeight(.semibold)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Button(action: {
                        if !userAnswer.isEmpty {
                            onAnswerSubmitted()
                        }
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(userAnswer.isEmpty)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct QuizResultView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let onDismiss: () -> Void
    let onRetake: () -> Void
    let noWordsToRetake: Bool
    let gradient: LinearGradient
    
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
                .foregroundColor(noWordsToRetake ? .green : (percentage >= 80 ? .yellow : .blue))
            
            VStack(spacing: 16) {
                Text(noWordsToRetake ? "No Words to Retake" : "Quiz Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !noWordsToRetake {
                VStack(spacing: 8) {
                    Text("\(correctAnswers) out of \(totalQuestions) correct")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(Int(percentage))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(percentage >= 80 ? .green : .blue)
                }
                
                Button(action: onRetake) {
                    Text("Retake Quiz")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            
            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct NoWordsView: View {
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No words due for review!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Great job! All your words are up to date. Add some new words to start learning.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    QuizView()
} 