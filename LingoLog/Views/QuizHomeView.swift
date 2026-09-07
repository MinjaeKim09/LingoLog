import SwiftUI

struct QuizHomeView: View {
    @ObservedObject var viewModel: QuizHomeViewModel
    let onStartQuiz: () -> Void
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isReady: Bool { !viewModel.wordsDue.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageHeader(
                    "Practice",
                    subtitle: "A few focused recalls make a word feel natural."
                )

                practiceStage

                VStack(alignment: .leading, spacing: 13) {
                    SectionHeading(title: "Your rhythm")
                    VStack(spacing: 15) {
                        HStack {
                            Label("Last 14 days", systemImage: "flame.fill")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.Colors.warning)
                            Spacer()
                            Text("Small steps count")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        StreakCalendarView()
                    }
                    .padding(18)
                    .glassCard()
                }
            }
            .padding(.horizontal, Theme.Metrics.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .onAppear { viewModel.refresh() }
    }

    private var practiceStage: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                RecallDeckMark(isReady: isReady)

                VStack(alignment: .leading, spacing: 5) {
                    Text(isReady ? "Ready to recall" : "All clear")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))

                    if isReady {
                        Text("\(viewModel.wordsDue.count) \(viewModel.wordsDue.count == 1 ? "word is" : "words are") waiting.")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                    } else if viewModel.nextReviewDate != nil {
                        Text(viewModel.timeRemaining)
                            .font(.system(.title2, design: .rounded).weight(.heavy).monospacedDigit())
                            .contentTransition(.numericText())
                            .onReceive(timer) { _ in viewModel.updateTimer() }
                        Text("until the next round")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.76))
                    } else {
                        Text("Nothing to review right now.")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                    }
                }
            }

            Text(isReady
                 ? "Type the meaning, check your answer, then move the word forward."
                 : "Newly saved words will show up here when they’re ready for another look.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onStartQuiz) {
                Label("Start recall", systemImage: "arrow.forward")
            }
            .lightButtonStyle()
            .disabled(!isReady)

            if isReady {
                Label("Corrected a miss? Swipe left to keep moving.", systemImage: "hand.draw.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(isReady ? Theme.Colors.violetField : Theme.Colors.accentField)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous))
    }
}

private struct RecallDeckMark: View {
    let isReady: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.16))
                .frame(width: 54, height: 58)
                .rotationEffect(.degrees(-8))
                .offset(x: -7, y: 2)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.28))
                .frame(width: 54, height: 58)
                .rotationEffect(.degrees(6))
                .offset(x: 7, y: 2)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .frame(width: 54, height: 58)
            Image(systemName: isReady ? "arrow.triangle.2.circlepath" : "checkmark")
                .font(.title3.weight(.heavy))
                .foregroundStyle(isReady ? Theme.Colors.violetField : Theme.Colors.accentField)
        }
        .frame(width: 70, height: 66)
        .accessibilityHidden(true)
    }
}
