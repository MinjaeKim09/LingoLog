import SwiftUI

struct DashboardView: View {
    @ObservedObject var userManager: UserManager
    let dataManager: DataManager
    let wordRepository: WordRepository
    let translationService: TranslationService
    @StateObject private var viewModel: DashboardViewModel
    @State private var showingAddWord = false
    @State private var showingQuiz = false

    init(wordRepository: WordRepository, dataManager: DataManager, userManager: UserManager, translationService: TranslationService) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.userManager = userManager
        self.translationService = translationService
        _viewModel = StateObject(wrappedValue: DashboardViewModel(wordRepository: wordRepository, dataManager: dataManager))
    }

    private var greeting: String {
        userManager.displayName.isEmpty ? "Your language,\nmade memorable." : "Hello, \(userManager.displayName)."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("LINGOLOG")
                            .font(.caption.weight(.bold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.Colors.accent)
                        Text(greeting)
                            .font(.system(size: 40, weight: .regular))
                            .tracking(-1.4)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .minimumScaleFactor(0.8)
                        Text("Build a vocabulary that stays with you.")
                            .font(.title3)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, 12)

                    HStack(spacing: 12) {
                        QuickActionButton(title: "Add a word", subtitle: "Capture something new", icon: "plus") { showingAddWord = true }
                        QuickActionButton(title: "Review", subtitle: "\(viewModel.wordsDueForReview) ready today", icon: "arrow.right") { showingQuiz = true }
                    }

                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Your progress").font(.title2.weight(.medium))
                            Spacer()
                            Text("THIS WEEK").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(Theme.Colors.textSecondary)
                        }

                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(viewModel.learningStreak)").font(.system(size: 58, weight: .regular)).tracking(-2)
                            Text(viewModel.learningStreak == 1 ? "day streak" : "day streak")
                                .font(.headline).foregroundStyle(Theme.Colors.textSecondary).padding(.bottom, 10)
                            Spacer()
                            Image(systemName: "flame.fill").font(.title2).foregroundStyle(Theme.Colors.accent)
                        }

                        GeometryReader { proxy in
                            let ratio = viewModel.totalWords == 0 ? 0 : CGFloat(viewModel.masteredWords) / CGFloat(viewModel.totalWords)
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.Colors.inactive).frame(height: 5)
                                Capsule().fill(Theme.Colors.accent).frame(width: proxy.size.width * ratio, height: 5)
                            }
                        }
                        .frame(height: 5)

                        HStack {
                            Metric(value: "\(viewModel.totalWords)", label: "words saved")
                            Spacer()
                            Metric(value: "\(viewModel.masteredWords)", label: "mastered")
                            Spacer()
                            Metric(value: "\(viewModel.wordsDueForReview)", label: "due now")
                        }
                    }
                    .padding(24)
                    .glassCard()

                    if !wordRepository.words.isEmpty {
                        RecentWordsSection(wordRepository: wordRepository)
                    } else {
                        EmptyStateView()
                    }
                }
                .padding(.horizontal, Theme.Metrics.pagePadding)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddWord) { AddWordView(dataManager: dataManager, translationService: translationService) }
            .sheet(isPresented: $showingQuiz) { QuizView(wordRepository: wordRepository, dataManager: dataManager) }
        }
        .onAppear { viewModel.refresh() }
    }
}

private struct Metric: View {
    let value: String; let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title2.weight(.medium)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

struct QuickActionButton: View {
    let title: String; let subtitle: String; let icon: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                HStack { Image(systemName: icon).font(.headline); Spacer() }
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.title3.weight(.medium))
                    Text(subtitle).font(.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint(subtitle)
    }
}

struct RecentWordsSection: View {
    @ObservedObject var wordRepository: WordRepository
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recently added").font(.title2.weight(.medium))
                Spacer()
                Text("LATEST").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(Theme.Colors.textSecondary)
            }.padding(.bottom, 12)
            ForEach(Array(wordRepository.words.prefix(5)), id: \.id) { word in
                HStack(spacing: 14) {
                    Circle().fill(Theme.Colors.accent).frame(width: 7, height: 7)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(word.word ?? "").font(.headline)
                        Text(word.translation ?? "").font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Text(word.language ?? "").font(.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, 15)
                if word.id != wordRepository.words.prefix(5).last?.id { Divider().foregroundStyle(Theme.Colors.divider) }
            }
        }
        .padding(22)
        .glassCard()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your first word starts here.").font(.title2.weight(.medium))
            Text("Save a word you want to remember. LingoLog will bring it back at the right time.")
                .foregroundStyle(Theme.Colors.textSecondary)
            Image(systemName: "arrow.up.right").foregroundStyle(Theme.Colors.accent).padding(.top, 8)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(24).glassCard()
    }
}

#Preview { DashboardView(wordRepository: WordRepository(dataManager: .shared), dataManager: .shared, userManager: .shared, translationService: .shared) }
