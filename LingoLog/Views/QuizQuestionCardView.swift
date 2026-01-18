import SwiftUI
import UIKit

struct QuizQuestionCardView: View {
    let word: WordEntry
    let questionIndex: Int
    let totalQuestions: Int
    @Binding var showingAnswer: Bool
    @Binding var userAnswer: String
    @Binding var isCorrect: Bool
    let onAnswerSubmitted: () -> Void
    let onNext: () -> Void
    let onEdit: () -> Void
    
    private var isCorrectionMatch: Bool {
        guard let translation = word.translation else { return false }
        return userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == translation.lowercased()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
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
                                    .fill(index < Int(word.masteryLevel) ? Theme.Colors.success : Theme.Colors.inactive)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer().frame(height: 16)
                
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
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
                    .padding(.top, 0)
                    
                    VStack(spacing: 12) {
                        TextField("Type your answer", text: $userAnswer)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                            .padding(16)
                            .background(Theme.Colors.inputBackground)
                            .cornerRadius(16)
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        showingAnswer && !isCorrect
                                            ? (isCorrectionMatch ? Theme.Colors.success : Theme.Colors.error.opacity(0.5))
                                            : Theme.Colors.accent.opacity(0.3),
                                        lineWidth: showingAnswer && !isCorrect ? 2 : 1
                                    )
                            )
                            .animation(.easeInOut, value: isCorrectionMatch)
                            .disabled(showingAnswer && isCorrect)
                            .onSubmit {
                                if !userAnswer.isEmpty {
                                    if !showingAnswer {
                                        onAnswerSubmitted()
                                    } else if isCorrectionMatch {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            onNext()
                                        }
                                    }
                                }
                            }
                        
                        if showingAnswer {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isCorrect ? Theme.Colors.success : Theme.Colors.error)
                                    
                                    if isCorrect {
                                        Text("Correct!")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(Theme.Colors.success)
                                            .fontWeight(.semibold)
                                    } else {
                                        Text("Type the correct answer:")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(Theme.Colors.error)
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                if !isCorrect {
                                    Text(word.translation ?? "")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.vertical, 4)
                                }
                            }
                            
                            if !isCorrect {
                                VStack(spacing: 12) {
                                    Button(action: {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            onNext()
                                        }
                                    }) {
                                        Text("Continue")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .primaryButtonStyle()
                                    .disabled(!isCorrectionMatch)
                                    .opacity(isCorrectionMatch ? 1.0 : 0.5)
                                    .animation(.easeInOut, value: isCorrectionMatch)
                                    
                                    Button(action: onEdit) {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit Word")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding()
                                    .foregroundColor(Theme.Colors.secondaryAccent)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.Colors.secondaryAccent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        } else {
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
                }
                .padding(24)
                .glassCard()
                .padding(.horizontal, 24)
                
                Spacer(minLength: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        }
    }
}
