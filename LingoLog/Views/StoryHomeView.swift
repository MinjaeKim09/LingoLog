import SwiftUI

struct StoryHomeView: View {
    @ObservedObject var viewModel: StoryViewModel
    @ObservedObject var storeManager: StoreManager = .shared
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.sectionSpacing) {
                    PageHeader(
                        "Stories",
                        subtitle: "Your \(viewModel.activeLanguageName) words, woven into something worth reading."
                    )

                    if !viewModel.isGeminiConfigured {
                        messageCard(
                            icon: "exclamationmark.icloud.fill",
                            color: Theme.Colors.warning,
                            title: "Story service unavailable",
                            message: "The story service needs to be configured before a reading can be created."
                        )
                    } else if !viewModel.hasWords {
                        messageCard(
                            icon: "character.book.closed.fill",
                            color: Theme.Colors.secondaryAccent,
                            title: "Build your word list first",
                            message: "Save a few \(viewModel.activeLanguageName) words, then return to see them in context."
                        )
                    } else {
                        todaySection
                        if !viewModel.storyHistory.isEmpty { recentStoriesSection }
                    }
                }
                .padding(.horizontal, Theme.Metrics.pagePadding)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
            .alert("Something went wrong", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(storeManager: storeManager)
                .presentationCornerRadius(28)
        }
        .task { await viewModel.loadSupportedLanguages() }
    }

    private func messageCard(icon: String, color: Color, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            IconTile(symbol: icon, color: color, size: 56)
            VStack(spacing: 6) {
                Text(title).font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .glassCard()
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Today’s reading")
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasTodayStory {
                    todayStoryCard
                } else {
                    generateStoryCard
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(viewModel.hasTodayStory ? Theme.Colors.violetField : Theme.Colors.skyField)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous))
        }
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            StoryStackMark()
            ProgressView().tint(.white)
            VStack(spacing: 4) {
                Text("Writing today’s story").font(.headline)
                Text("Bringing your vocabulary into context…").font(.caption).foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var todayStoryCard: some View {
        VStack(spacing: 18) {
            if let story = viewModel.todayStory {
                StoryStackMark(completed: story.quizCompleted)

                VStack(spacing: 7) {
                    Text(story.title ?? "Today’s Story")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        Label(story.formattedDate, systemImage: "calendar")
                        if story.quizCompleted {
                            Label("\(story.quizScore)/\(story.quizQuestions.count)", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Theme.Colors.success)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                }

                Button {
                    if storeManager.isStoryUnlocked { viewModel.selectStory(story) }
                    else { showingPaywall = true }
                } label: {
                    Label(storeManager.isStoryUnlocked ? "Open story" : "Unlock stories", systemImage: storeManager.isStoryUnlocked ? "book.fill" : "lock.fill")
                }
                .lightButtonStyle()
            }
        }
    }

    private var generateStoryCard: some View {
        VStack(spacing: 18) {
            StoryStackMark()

            VStack(spacing: 6) {
                Text("A new story awaits")
                    .font(.title2.weight(.semibold))
                Text("We’ll use words from your collection so the reading feels familiar and useful.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Button {
                if storeManager.isStoryUnlocked {
                    Task { await viewModel.loadOrGenerateStory() }
                } else {
                    showingPaywall = true
                }
            } label: {
                Label(
                    storeManager.isStoryUnlocked ? "Create today’s story" : "Unlock stories",
                    systemImage: storeManager.isStoryUnlocked ? "square.and.pencil" : "lock.fill"
                )
            }
            .lightButtonStyle()
            .disabled(storeManager.isStoryUnlocked && viewModel.wordsForSelectedLanguage.count < 3)

            if viewModel.wordsForSelectedLanguage.count < 3 {
                Label("Save at least 3 words first", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.76))
            }
        }
    }

    private var recentStoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Recent stories", actionTitle: storeManager.isStoryUnlocked ? "See all" : nil) {
                viewModel.navigateTo(.history)
            }

            VStack(spacing: 0) {
                ForEach(Array(viewModel.storyHistory.prefix(3).enumerated()), id: \.element.id) { index, story in
                    StoryHistoryRow(story: story) {
                        if storeManager.isStoryUnlocked { viewModel.selectStory(story) }
                        else { showingPaywall = true }
                    }
                    .padding(.horizontal, 17)
                    .padding(.vertical, 12)
                    if index < min(viewModel.storyHistory.count, 3) - 1 {
                        Divider().padding(.leading, 17)
                    }
                }
            }
            .glassCard()
        }
    }
}

struct StoryHistoryRow: View {
    let story: DailyStory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(story.title ?? "Untitled")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    Text("\(story.formattedDate) · \(story.language ?? "")")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .tactileButtonStyle()
    }
}

private struct StoryStackMark: View {
    var completed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.white.opacity(0.18))
                .frame(width: 62, height: 54)
                .rotationEffect(.degrees(-7))
                .offset(x: -8, y: 3)
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.white.opacity(0.28))
                .frame(width: 62, height: 54)
                .rotationEffect(.degrees(6))
                .offset(x: 8, y: 3)
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.white)
                .frame(width: 62, height: 54)
            if completed {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.Colors.violetField)
            } else {
                VStack(spacing: 5) {
                    Capsule().fill(Theme.Colors.skyField).frame(width: 30, height: 5)
                    Capsule().fill(Theme.Colors.skyField.opacity(0.55)).frame(width: 22, height: 5)
                }
            }
        }
        .frame(width: 82, height: 68)
        .accessibilityHidden(true)
    }
}

#Preview {
    StoryHomeView(viewModel: StoryViewModel(
        wordRepository: WordRepository(dataManager: .shared),
        storyRepository: StoryRepository(dataManager: .shared),
        languageSpaceManager: .shared
    ))
}
