import SwiftUI

struct StoryHomeView: View {
    @ObservedObject var viewModel: StoryViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Theme.Typography.display("Daily Stories")
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Theme.Typography.body("Learn through reading")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    if !viewModel.isGeminiConfigured {
                        // API Not Configured Warning
                        apiNotConfiguredView
                    } else if !viewModel.hasWords {
                        // No words added yet
                        noWordsView
                    } else {
                        // Language Picker
                        languagePickerSection
                        
                        // Today's Story Card
                        todayStorySection
                        
                        // Recent Stories
                        if !viewModel.storyHistory.isEmpty {
                            recentStoriesSection
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - API Not Configured View
    
    private var apiNotConfiguredView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.warning.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.warning)
            }
            
            VStack(spacing: 8) {
                Theme.Typography.title("API Key Required")
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Theme.Typography.body("To generate stories, please add your Gemini API key to Secrets.plist")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .glassCard()
    }
    
    // MARK: - No Words View
    
    private var noWordsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondaryAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "text.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.secondaryAccent)
            }
            
            VStack(spacing: 8) {
                Theme.Typography.title("Add Words First")
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Theme.Typography.body("Add some vocabulary words to generate personalized stories")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .glassCard()
    }
    
    // MARK: - Language Picker Section
    
    private var languagePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Theme.Typography.title("Language")
                .font(.headline)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, 4)
            
            HStack {
                Theme.Typography.body("Story Language")
                    .foregroundColor(Theme.Colors.textPrimary)
                Spacer()
                
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.accent)
            }
            .padding()
            .glassCard()
            
            Text("\(viewModel.wordsForSelectedLanguage.count) words available")
                .font(.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, 4)
        }
    }
    
    // MARK: - Today's Story Section
    
    private var todayStorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Theme.Typography.title("Today's Story")
                .font(.headline)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasTodayStory {
                    todayStoryCard
                } else {
                    generateStoryCard
                }
            }
            .padding(24)
            .glassCard()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.Colors.accent)
            
            Theme.Typography.body("Generating your story...")
                .foregroundStyle(Theme.Colors.textSecondary)
            
            Theme.Typography.body("This may take a moment")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var todayStoryCard: some View {
        VStack(spacing: 16) {
            if let story = viewModel.todayStory {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(Theme.Colors.success)
                }
                
                VStack(spacing: 4) {
                    Theme.Typography.title(story.title ?? "Today's Story")
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    if story.quizCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.Colors.success)
                            Text("Quiz completed: \(story.quizScore)/\(story.quizQuestions.count)")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    } else {
                        Text("Quiz not completed yet")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryAccent)
                    }
                }
                
                Button(action: {
                    viewModel.selectStory(story)
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Read Story")
                    }
                    .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
            }
        }
    }
    
    private var generateStoryCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 35))
                    .foregroundStyle(Theme.Colors.accent)
            }
            
            VStack(spacing: 4) {
                Theme.Typography.title("Ready to Generate")
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Theme.Typography.body("Create a story using your vocabulary words")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await viewModel.loadOrGenerateStory()
                }
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Story")
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(viewModel.wordsForSelectedLanguage.count < 3)
            .opacity(viewModel.wordsForSelectedLanguage.count < 3 ? 0.5 : 1.0)
            
            if viewModel.wordsForSelectedLanguage.count < 3 {
                Text("Need at least 3 words to generate a story")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.error)
            }
        }
    }
    
    // MARK: - Recent Stories Section
    
    private var recentStoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Theme.Typography.title("Recent Stories")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    viewModel.navigateTo(.history)
                }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(viewModel.storyHistory.prefix(3)) { story in
                    StoryHistoryRow(story: story) {
                        viewModel.selectStory(story)
                    }
                }
            }
            .padding()
            .glassCard()
        }
    }
}

// MARK: - Story History Row

struct StoryHistoryRow: View {
    let story: DailyStory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title ?? "Untitled")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    
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
                
                if story.quizCompleted {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.success)
                        Text("\(story.quizScore)/\(story.quizQuestions.count)")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StoryHomeView(viewModel: StoryViewModel(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared)
    ))
}
