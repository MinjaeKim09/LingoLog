import SwiftUI
import Combine
import UIKit

struct QuizView: View {
    @State private var showingSession = false
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            if showingSession {
                QuizSessionView(
                    onValidationComplete: {
                        // After quiz validation/completion, we can return to home
                        // The session view handles its own internal "Done" state which calls onDismiss
                    },
                    onDismiss: {
                        withAnimation {
                            showingSession = false
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                QuizHomeView(onStartQuiz: {
                    withAnimation {
                        showingSession = true
                    }
                })
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
    }
}

// MARK: - Quiz Home View

private struct QuizHomeView: View {
    @ObservedObject var dataManager = DataManager.shared
    let onStartQuiz: () -> Void
    
    // Countdown timer
    @State private var timeRemaining: String = ""
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var wordsDue: [WordEntry] {
        dataManager.fetchWordsDueForReview()
    }
    
    private var nextReviewDate: Date? {
        let allWords = dataManager.fetchWords()
        let unmastered = allWords.filter { !$0.isMastered && $0.nextReviewDate != nil }
        return unmastered.compactMap { $0.nextReviewDate }.min()
    }
    
    private var isReady: Bool {
        !wordsDue.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Theme.Typography.display("Quiz Time")
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Theme.Typography.body("Keep your streak alive!")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, 40)
                
                // Status Section
                VStack(spacing: 24) {
                    if isReady {
                        // Ready State
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.accent.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Theme.Colors.accent)
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(wordsDue.count)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                
                                Text(wordsDue.count == 1 ? "word ready" : "words ready")
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    } else {
                        // Waiting State
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.secondaryAccent.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Theme.Colors.secondaryAccent)
                            }
                            
                            VStack(spacing: 4) {
                                if let nextDate = nextReviewDate {
                                    Text("Next Review In")
                                        .font(.caption)
                                        .textCase(.uppercase)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                    
                                    Text(timeRemaining)
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                        .onReceive(timer) { _ in
                                            updateTimer(targetDate: nextDate)
                                        }
                                        .onAppear {
                                            updateTimer(targetDate: nextDate)
                                        }
                                } else {
                                    Text("All Caught Up!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Theme.Colors.success)
                                    
                                    Text("Add more words to continue learning")
                                        .font(.body)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Button(action: onStartQuiz) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Take Quiz")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                    .disabled(!isReady)
                    .opacity(isReady ? 1.0 : 0.5)
                }
                .padding(32)
                .glassCard()
                .padding(.horizontal)
                
                // Streak Calendar Section
                VStack(spacing: 16) {
                    HStack {
                        Theme.Typography.title("Study Streak")
                        Spacer()
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Theme.Colors.warning)
                    }
                    
                    StreakCalendarView()
                }
                .padding(24)
                .glassCard()
                .padding(.horizontal)
            }
        }
    }
    
    private func updateTimer(targetDate: Date) {
        let now = Date()
        let diff = targetDate.timeIntervalSince(now)
        
        if diff <= 0 {
            timeRemaining = "Ready!"
        } else {
            let hours = Int(diff) / 3600
            let minutes = (Int(diff) % 3600) / 60
            let seconds = Int(diff) % 60
            timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}

// MARK: - Streak Calendar View

private struct StreakCalendarView: View {
    let daysToDisplay = 14
    let historyManager = StudyHistoryManager.shared
    
    private var dates: [Date] {
        historyManager.getRecentHistory(days: daysToDisplay)
    }
    
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                // Day headers (only need one row if we map dates to day accessors, but simple grid is easier)
                ForEach(0..<7, id: \.self) { index in
                    Text(weekDays[index])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                
                ForEach(dates, id: \.self) { date in
                    let hasStudied = historyManager.hasStudied(on: date)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    ZStack {
                        Circle()
                            .fill(hasStudied ? Theme.Colors.success : (isToday ? Theme.Colors.accent.opacity(0.1) : Color.gray.opacity(0.1)))
                            .frame(width: 30, height: 30)
                        
                        // If it's today and not studied yet, show outline
                        if isToday && !hasStudied {
                            Circle()
                                .stroke(Theme.Colors.accent, lineWidth: 1)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Quiz Session View (Refactored from original QuizView)

private struct QuizSessionView: View {
    @ObservedObject var dataManager = DataManager.shared
    var onValidationComplete: () -> Void
    var onDismiss: () -> Void
    
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
    @State private var showFeedbackOverlay = false
    @State private var feedbackColor: Color = .clear
    @State private var feedbackIcon: String = ""
    
    var currentWord: WordEntry? {
        guard currentWordIndex < wordsDueForReview.count else { return nil }
        return wordsDueForReview[currentWordIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if quizCompleted {
                    QuizResultView(
                        correctAnswers: correctAnswers,
                        totalQuestions: totalQuestions,
                        onDismiss: onDismiss,
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
                    // Fallback, though Home view should prevent this
                    NoWordsView()
                        .transition(.opacity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Quit") { onDismiss() }
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .onAppear {
                loadWordsForQuiz()
            }
        }
        .navigationViewStyle(.stack)
        // --- FEEDBACK OVERLAY ---
        .overlay(
            Group {
                if showFeedbackOverlay {
                    feedbackColor
                        .ignoresSafeArea()
                        .opacity(0.3)
                        .transition(.opacity)
                    
                    VStack {
                        Spacer()
                        Image(systemName: feedbackIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(Color.white)
                            .shadow(radius: 10)
                            .scaleEffect(1.0)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showFeedbackOverlay)
        )
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
            // Record streak on successful answer (or completion)
            StudyHistoryManager.shared.recordStudySession()
        }
        // Update word mastery level
        word.updateMasteryLevel(correct: isAnswerCorrect)
        dataManager.save()
        
        // Feedback overlay setup
        feedbackColor = isAnswerCorrect ? Theme.Colors.success : Theme.Colors.error
        feedbackIcon = isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
        showFeedbackOverlay = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        if isAnswerCorrect {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.error)
        }
        
        // Proceed logic
        let delay = isAnswerCorrect ? 0.7 : 1.2
        if !isAnswerCorrect {
            showingAnswer = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
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

// MARK: - Supporting Views

private struct QuizQuestionCardView: View {
    let word: WordEntry
    let questionIndex: Int
    let totalQuestions: Int
    @Binding var showingAnswer: Bool
    @Binding var userAnswer: String
    @Binding var isCorrect: Bool
    let onAnswerSubmitted: () -> Void
    
    var body: some View {
        ScrollView {
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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        }
    }
}

private struct QuizResultView: View {
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
        ScrollView {
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
}

private struct NoWordsView: View {
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