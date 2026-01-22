import SwiftUI

struct QuizHomeView: View {
    @ObservedObject var viewModel: QuizHomeViewModel
    let onStartQuiz: () -> Void
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var isReady: Bool {
        !viewModel.wordsDue.isEmpty
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
                                Text("\(viewModel.wordsDue.count)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                
                                Text(viewModel.wordsDue.count == 1 ? "word ready" : "words ready")
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    } else {
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
                                if let _ = viewModel.nextReviewDate {
                                    Text("Next Review In")
                                        .font(.caption)
                                        .textCase(.uppercase)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                    
                                    Text(viewModel.timeRemaining)
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                        .onReceive(timer) { _ in
                                            viewModel.updateTimer()
                                        }
                                        .onAppear {
                                            viewModel.updateTimer()
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
        .onAppear {
            viewModel.refresh()
        }
    }
}
