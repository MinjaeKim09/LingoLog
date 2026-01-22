import SwiftUI
import UIKit

struct QuizSessionView: View {
    @ObservedObject var viewModel: QuizSessionViewModel
    let onDismiss: () -> Void
    
    @Namespace private var animation
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.quizCompleted {
                    QuizResultView(
                        correctAnswers: viewModel.correctAnswers,
                        totalQuestions: viewModel.totalQuestions,
                        onDismiss: onDismiss,
                        onRetake: viewModel.retakeQuiz,
                        noWordsToRetake: viewModel.noWordsToRetake
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                } else if let word = viewModel.currentWord {
                    QuizQuestionCardView(
                        word: word,
                        questionIndex: viewModel.currentWordIndex + 1,
                        totalQuestions: viewModel.totalQuestions,
                        showingAnswer: $viewModel.showingAnswer,
                        userAnswer: $viewModel.userAnswer,
                        isCorrect: $viewModel.isCorrect,
                        onAnswerSubmitted: {
                            viewModel.handleAnswerWithFeedback()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(viewModel.isCorrect ? .success : .error)
                        },
                        onNext: viewModel.moveToNextWord,
                        onEdit: {
                            viewModel.wordToEdit = viewModel.currentWord
                        }
                    )
                    .matchedGeometryEffect(id: "card", in: animation)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .animation(.easeInOut, value: viewModel.currentWordIndex)
                } else {
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
                viewModel.loadWordsForQuiz()
            }
            .sheet(item: $viewModel.wordToEdit) { word in
                EditWordView(word: word, dataManager: viewModel.dataManager)
            }
        }
        .navigationViewStyle(.stack)
        .overlay(
            Group {
                if viewModel.showFeedbackOverlay {
                    viewModel.feedbackColor
                        .ignoresSafeArea()
                        .opacity(0.3)
                        .transition(.opacity)
                    
                    VStack {
                        Spacer()
                        Image(systemName: viewModel.feedbackIcon)
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
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.showFeedbackOverlay)
        )
    }
}
