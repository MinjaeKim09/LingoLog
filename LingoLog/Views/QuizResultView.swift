import SwiftUI

struct QuizResultView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let onDismiss: () -> Void
    let onRetake: () -> Void
    let noWordsToRetake: Bool

    private var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }

    private var message: String {
        if noWordsToRetake { return "Nothing is due right now. Come back later or save another word." }
        if percentage >= 0.8 { return "Strong recall. That practice is paying off." }
        if percentage >= 0.6 { return "Nice work. Another pass will make these stick." }
        return "Every review strengthens the memory. Keep going."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                ResultMark(isStrong: noWordsToRetake || percentage >= 0.8)

                VStack(spacing: 9) {
                    Text(noWordsToRetake ? "You’re caught up" : "Review complete")
                        .font(.title.weight(.bold))
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                if !noWordsToRetake {
                    HStack(spacing: 0) {
                        resultMetric("\(correctAnswers)", "Correct")
                        Divider().frame(height: 40)
                        resultMetric("\(totalQuestions)", "Reviewed")
                        Divider().frame(height: 40)
                        resultMetric("\(Int(percentage * 100))%", "Score")
                    }
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button(action: onRetake) {
                        Text("Review missed words")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .tactileButtonStyle()
                }

                Button("Done", action: onDismiss)
                    .lightButtonStyle()
            }
            .foregroundStyle(.white)
            .padding(24)
            .background(noWordsToRetake || percentage >= 0.8 ? Theme.Colors.accentField : Theme.Colors.violetField)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous))
            .padding(Theme.Metrics.pagePadding)
            .padding(.top, 32)
        }
    }

    private func resultMetric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3.weight(.semibold)).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ResultMark: View {
    let isStrong: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 74, height: 74)
                .offset(x: -9)
            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: 74, height: 74)
                .offset(x: 9)
            Circle()
                .fill(.white)
                .frame(width: 66, height: 66)
            Image(systemName: isStrong ? "checkmark" : "arrow.counterclockwise")
                .font(.title2.weight(.heavy))
                .foregroundStyle(isStrong ? Theme.Colors.accentField : Theme.Colors.violetField)
        }
        .frame(width: 100, height: 78)
        .accessibilityHidden(true)
    }
}
