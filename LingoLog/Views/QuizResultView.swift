import SwiftUI

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
