import SwiftUI

struct DashboardView: View {
    @ObservedObject var userManager: UserManager
    let dataManager: DataManager
    let wordRepository: WordRepository
    let translationService: TranslationService
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    @ObservedObject var storeManager: StoreManager
    @StateObject private var viewModel: DashboardViewModel
    @State private var showingAddWord = false
    @State private var showingQuiz = false
    @State private var showingLanguageSpaces = false

    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        userManager: UserManager,
        translationService: TranslationService,
        languageSpaceManager: LanguageSpaceManager,
        storeManager: StoreManager
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.userManager = userManager
        self.translationService = translationService
        self.languageSpaceManager = languageSpaceManager
        self.storeManager = storeManager
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            wordRepository: wordRepository,
            dataManager: dataManager,
            languageSpaceManager: languageSpaceManager
        ))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return userManager.displayName.isEmpty ? salutation : "\(salutation), \(userManager.displayName)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        header

                        DailyLoopCard(
                            languageName: languageSpaceManager.activeSpace?.learningLanguageName ?? "Language",
                            totalWords: viewModel.totalWords,
                            masteredWords: viewModel.masteredWords,
                            dueWords: viewModel.wordsDueForReview,
                            streak: viewModel.learningStreak,
                            onSave: { showingAddWord = true },
                            onPractice: { showingQuiz = true }
                        )

                        WordTrailView(
                            totalWords: viewModel.totalWords,
                            dueWords: viewModel.wordsDueForReview,
                            masteredWords: viewModel.masteredWords
                        )

                        if viewModel.totalWords > 0 {
                            RecentWordsSection(
                                wordRepository: wordRepository,
                                languageCode: languageSpaceManager.activeSpace?.learningLanguageCode
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Metrics.pagePadding)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddWord) {
                AddWordView(
                    dataManager: dataManager,
                    translationService: translationService,
                    languageSpaceManager: languageSpaceManager
                )
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showingQuiz) {
                QuizView(
                    wordRepository: wordRepository,
                    dataManager: dataManager,
                    languageSpaceManager: languageSpaceManager
                )
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showingLanguageSpaces) {
                LanguageSpacesView(
                    languageSpaceManager: languageSpaceManager,
                    storeManager: storeManager,
                    translationService: translationService
                )
                .presentationCornerRadius(28)
            }
        }
        .onAppear { viewModel.refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageHeader(greeting, subtitle: "Keep a word. Meet it again. Make it yours.")

            if let space = languageSpaceManager.activeSpace {
                LanguageSpaceSwitcher(space: space) {
                    showingLanguageSpaces = true
                }
            }
        }
    }
}

private struct DailyLoopCard: View {
    let languageName: String
    let totalWords: Int
    let masteredWords: Int
    let dueWords: Int
    let streak: Int
    let onSave: () -> Void
    let onPractice: () -> Void

    private var headline: String {
        if dueWords > 0 {
            return "\(dueWords) \(dueWords == 1 ? "word is" : "words are") ready to stick."
        }
        if totalWords == 0 {
            return "Catch one word before it disappears."
        }
        return "Your words are resting. Add another?"
    }

    private var supportingText: String {
        if dueWords > 0 { return "A quick round is all it takes to strengthen them." }
        if totalWords == 0 { return "Save it now. LingoLog will bring it back later." }
        return "Nothing is due yet. Your next review will arrive at the right time."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today’s loop")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                    Text(languageName)
                        .font(.caption)
                        .opacity(0.78)
                }
                Spacer()
                if streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .padding(.horizontal, 11)
                        .frame(minHeight: 36)
                        .background(.white.opacity(0.16), in: Capsule())
                        .accessibilityLabel("\(streak) day streak")
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(headline)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .fixedSize(horizontal: false, vertical: true)
                Text(supportingText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if dueWords > 0 {
                Button(action: onPractice) {
                    Label("Practice now", systemImage: "arrow.forward")
                }
                .lightButtonStyle()

                Button(action: onSave) {
                    Label("Save another word", systemImage: "plus")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .tactileButtonStyle()
            } else {
                Button(action: onSave) {
                    Label("Save a word", systemImage: "plus")
                }
                .lightButtonStyle()

                Label(totalWords == 0 ? "Practice unlocks when a word is ready" : "Practice is caught up", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack(spacing: 0) {
                loopStat(value: totalWords, label: "saved")
                loopDivider
                loopStat(value: masteredWords, label: "solid")
                loopDivider
                loopStat(value: dueWords, label: "ready")
            }
            .padding(.top, 2)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Theme.Colors.accentField)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func loopStat(value: Int, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(value)")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .opacity(0.76)
        }
        .frame(maxWidth: .infinity)
    }

    private var loopDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.2))
            .frame(width: 1, height: 24)
    }
}

private struct WordTrailView: View {
    let totalWords: Int
    let dueWords: Int
    let masteredWords: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            SectionHeading(title: "Your word trail")

            HStack(spacing: 8) {
                TrailMilestone(
                    value: totalWords,
                    label: "Catch",
                    mark: "Aa",
                    color: Theme.Colors.sky,
                    isActive: totalWords > 0
                )

                trailLine(color: totalWords > 0 ? Theme.Colors.sky : Theme.Colors.raised)

                TrailMilestone(
                    value: dueWords,
                    label: "Recall",
                    symbol: "arrow.triangle.2.circlepath",
                    color: Theme.Colors.violet,
                    isActive: totalWords > 0
                )

                trailLine(color: masteredWords > 0 ? Theme.Colors.violet : Theme.Colors.raised)

                TrailMilestone(
                    value: masteredWords,
                    label: "Keep",
                    symbol: "checkmark",
                    color: Theme.Colors.accent,
                    isActive: masteredWords > 0
                )
            }

            Text(totalWords == 0
                 ? "Every saved word starts here, then moves forward as you recall it."
                 : "Words move along the trail each time you remember them.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func trailLine(color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(maxWidth: .infinity)
            .frame(height: 6)
            .offset(y: -13)
    }
}

private struct TrailMilestone: View {
    let value: Int
    let label: String
    var mark: String? = nil
    var symbol: String? = nil
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.black.opacity(0.18) : Theme.Colors.neutralDepth)
                    .offset(y: 3)
                Circle()
                    .fill(isActive ? color : Theme.Colors.raised)
                if let mark {
                    Text(mark)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.subheadline.weight(.bold))
                }
            }
            .foregroundStyle(isActive ? .white : Theme.Colors.textTertiary)
            .frame(width: 50, height: 50)
            .padding(.bottom, 3)

            VStack(spacing: 1) {
                Text("\(value)")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .monospacedDigit()
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .frame(minWidth: 58)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct RecentWordsSection: View {
    @ObservedObject var wordRepository: WordRepository
    let languageCode: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Recently caught")

            VStack(spacing: 0) {
                let recentWords = Array(wordRepository.words(for: languageCode).prefix(5))
                ForEach(Array(recentWords.enumerated()), id: \.element.id) { index, word in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(word.word ?? "")
                                .font(.headline)
                            Text(word.translation ?? "")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < recentWords.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .glassCard()
        }
    }

}

#Preview {
    DashboardView(
        wordRepository: WordRepository(dataManager: .shared),
        dataManager: .shared,
        userManager: .shared,
        translationService: .shared,
        languageSpaceManager: LanguageSpaceManager.shared,
        storeManager: StoreManager.shared
    )
}
