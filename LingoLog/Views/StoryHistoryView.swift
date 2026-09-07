import SwiftUI

struct StoryHistoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    @ObservedObject var storeManager: StoreManager = .shared
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                    PageHeader("Story history", subtitle: "Return to past readings anytime.")
                    if !storeManager.isStoryUnlocked {
                        lockedStateView
                    } else if viewModel.storyHistory.isEmpty {
                        emptyStateView
                    } else {
                        // Stories List
                        storiesListSection
                    }
                    
                    Spacer(minLength: 50)
                    }
                    .padding(Theme.Metrics.pagePadding)
                }
                .scrollIndicators(.hidden)
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
                            Text("Back")
                        }
                        .foregroundStyle(Theme.Colors.accent)
                    }
                }
                
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(storeManager: storeManager)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondaryAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "text.book.closed.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.Colors.secondaryAccent)
            }
            
            VStack(spacing: 8) {
                Theme.Typography.title("No Stories Yet")
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Theme.Typography.body("Generate your first story to see it here")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.goBack()
            }) {
                Text("Go Back")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .padding(.top, 8)
        }
        .padding(32)
        .glassCard()
        .padding(.top, 40)
    }
    
    private var lockedStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.Colors.accent)
            }
            
            VStack(spacing: 8) {
                Theme.Typography.title("Daily Stories")
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Theme.Typography.body("Subscribe to read your story history.")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingPaywall = true
            }) {
                Text("Subscribe")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .padding(.top, 8)
        }
        .padding(32)
        .glassCard()
        .padding(.top, 40)
    }
    
    // MARK: - Stories List Section
    
    private var storiesListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.storyHistory) { story in
                StoryHistoryCard(story: story) {
                    if storeManager.isStoryUnlocked {
                        viewModel.selectStory(story)
                    } else {
                        showingPaywall = true
                    }
                }
            }
        }
    }
}

// MARK: - Story History Card

struct StoryHistoryCard: View {
    let story: DailyStory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title ?? "Untitled")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text(story.language ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.secondaryAccent.opacity(0.1))
                                .foregroundColor(Theme.Colors.secondaryAccent)
                                .cornerRadius(8)
                            
                            Text(story.formattedDate)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                
                // Preview text
                if let content = story.content {
                    Text(content)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                // Quiz Status
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "text.word.spacing")
                            .font(.caption)
                        Text("\(story.wordIDs.count) words")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if story.quizCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.Colors.success)
                            Text("Score: \(story.quizScore)/\(story.quizQuestions.count)")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.success)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Theme.Colors.warning)
                            Text("Quiz pending")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.warning)
                        }
                    }
                }
            }
            .padding(16)
            .glassCard()
        }
        .tactileButtonStyle()
    }
}

#Preview {
    StoryHistoryView(viewModel: StoryViewModel(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared),
        languageSpaceManager: LanguageSpaceManager.shared
    ))
}
