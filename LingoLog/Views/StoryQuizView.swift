import SwiftUI

struct StoryQuizView: View {
    @ObservedObject var viewModel: StoryViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.quizCompleted {
                    quizResultView
                } else {
                    quizQuestionView
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.goBack()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Story")
                        }
                        .foregroundStyle(Theme.Colors.accent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Theme.Typography.title("Quiz")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Quiz Question View
    
    private var quizQuestionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress
                progressSection
                
                // Question
                if let question = viewModel.currentQuizQuestion {
                    questionCard(question: question)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView(
                value: Double(viewModel.currentQuestionIndex),
                total: Double(max(viewModel.totalQuizQuestions, 1))
            )
            .accentColor(Theme.Colors.accent)
            
            HStack {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.totalQuizQuestions)")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.success)
                    Text("\(viewModel.quizScore)")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func questionCard(question: StoryQuizQuestion) -> some View {
        VStack(spacing: 24) {
            // Question Text
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.accent)
                
                Text(question.question)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 8)
            
            // Answer Options
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    AnswerOptionButton(
                        text: option,
                        index: index,
                        isSelected: viewModel.selectedAnswerIndex == index,
                        isCorrect: index == question.correctIndex,
                        showingFeedback: viewModel.showingAnswerFeedback
                    ) {
                        viewModel.selectAnswer(index)
                    }
                }
            }
            
            // Next Button (shown after answering)
            if viewModel.showingAnswerFeedback {
                Button(action: {
                    viewModel.moveToNextQuestion()
                }) {
                    HStack {
                        Text(viewModel.currentQuestionIndex + 1 >= viewModel.totalQuizQuestions ? "See Results" : "Next Question")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                .padding(.top, 8)
            }
        }
        .padding(24)
        .glassCard()
    }
    
    // MARK: - Quiz Result View
    
    private var quizResultView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Result Icon
                resultIcon
                
                // Score Display
                scoreDisplay
                
                // Message
                resultMessage
                
                // Actions
                resultActions
                
                Spacer(minLength: 50)
            }
            .padding()
            .padding(.top, 20)
        }
    }
    
    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(resultColor.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Image(systemName: resultIconName)
                .font(.system(size: 50))
                .foregroundStyle(resultColor)
        }
    }
    
    private var scoreDisplay: some View {
        VStack(spacing: 8) {
            Theme.Typography.display("Quiz Complete!")
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("\(viewModel.quizScore) out of \(viewModel.totalQuizQuestions)")
                .font(.title2)
                .foregroundStyle(Theme.Colors.textSecondary)
            
            Text("\(Int(scorePercentage))%")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundStyle(resultColor)
        }
    }
    
    private var resultMessage: some View {
        Text(resultMessageText)
            .font(.body)
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    private var resultActions: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.retakeQuiz()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retake Quiz")
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            
            Button(action: {
                viewModel.finishQuiz()
            }) {
                Text("Back to Stories")
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var scorePercentage: Double {
        guard viewModel.totalQuizQuestions > 0 else { return 0 }
        return Double(viewModel.quizScore) / Double(viewModel.totalQuizQuestions) * 100
    }
    
    private var resultColor: Color {
        if scorePercentage >= 75 {
            return Theme.Colors.success
        } else if scorePercentage >= 50 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.error
        }
    }
    
    private var resultIconName: String {
        if scorePercentage >= 75 {
            return "star.fill"
        } else if scorePercentage >= 50 {
            return "hand.thumbsup.fill"
        } else {
            return "book.fill"
        }
    }
    
    private var resultMessageText: String {
        if scorePercentage >= 75 {
            return "Excellent! You understood the story very well!"
        } else if scorePercentage >= 50 {
            return "Good job! Keep reading to improve your comprehension."
        } else {
            return "Keep practicing! Try reading the story again."
        }
    }
}

// MARK: - Answer Option Button

struct AnswerOptionButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let showingFeedback: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        if showingFeedback {
            if isCorrect {
                return Theme.Colors.success.opacity(0.15)
            } else if isSelected && !isCorrect {
                return Theme.Colors.error.opacity(0.15)
            }
        }
        return isSelected ? Theme.Colors.accent.opacity(0.1) : Color.clear
    }
    
    private var borderColor: Color {
        if showingFeedback {
            if isCorrect {
                return Theme.Colors.success
            } else if isSelected && !isCorrect {
                return Theme.Colors.error
            }
        }
        return isSelected ? Theme.Colors.accent : Theme.Colors.divider
    }
    
    private var textColor: Color {
        if showingFeedback {
            if isCorrect {
                return Theme.Colors.success
            } else if isSelected && !isCorrect {
                return Theme.Colors.error
            }
        }
        return Theme.Colors.textPrimary
    }
    
    private var optionLetter: String {
        let letters = ["A", "B", "C", "D"]
        return index < letters.count ? letters[index] : "\(index + 1)"
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(optionLetter)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(showingFeedback && isCorrect ? Theme.Colors.success :
                                    (showingFeedback && isSelected && !isCorrect ? Theme.Colors.error :
                                        (isSelected ? Theme.Colors.accent : Theme.Colors.textSecondary.opacity(0.5))))
                    )
                
                Text(text)
                    .font(.body)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if showingFeedback {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.success)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Colors.error)
                    }
                }
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected || (showingFeedback && isCorrect) ? 2 : 1)
            )
        }
        .disabled(showingFeedback)
        .buttonStyle(.plain)
    }
}

#Preview {
    StoryQuizView(viewModel: StoryViewModel(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared)
    ))
}
