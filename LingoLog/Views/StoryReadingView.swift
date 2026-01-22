import SwiftUI

struct StoryReadingView: View {
    @ObservedObject var viewModel: StoryViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let story = viewModel.currentStory {
                        // Story Header
                        storyHeader(story: story)
                        
                        // Story Content
                        storyContent(story: story)
                        
                        // Words Used Section
                        wordsUsedSection
                        
                        // Quiz Button
                        quizSection(story: story)
                        
                        Spacer(minLength: 50)
                    }
                }
                .padding()
            }
            .background(Theme.Colors.background)
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
                
                ToolbarItem(placement: .principal) {
                    Theme.Typography.title("Story")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Story Header
    
    private func storyHeader(story: DailyStory) -> some View {
        VStack(spacing: 12) {
            Text(story.title ?? "Untitled Story")
                .font(.system(.title, design: .serif))
                .fontWeight(.bold)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Label(story.language ?? "", systemImage: "globe")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                
                Label(story.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            
            if story.quizCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.success)
                    Text("Quiz Score: \(story.quizScore)/\(story.quizQuestions.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.success)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.success.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Story Content
    
    private func storyContent(story: DailyStory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(story.content ?? "")
                .font(.system(.body, design: .serif))
                .lineSpacing(8)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
    
    // MARK: - Words Used Section
    
    private var wordsUsedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed")
                    .foregroundStyle(Theme.Colors.accent)
                Theme.Typography.title("Vocabulary in Story")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.leading, 4)
            
            let words = viewModel.wordsUsedInStory()
            
            if words.isEmpty {
                Text("No vocabulary words found")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassCard()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(words, id: \.id) { word in
                        WordChip(word: word)
                    }
                }
                .padding()
                .glassCard()
            }
        }
    }
    
    // MARK: - Quiz Section
    
    private func quizSection(story: DailyStory) -> some View {
        VStack(spacing: 16) {
            if story.quizCompleted {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.success)
                        Text("Quiz Completed")
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    
                    Button(action: {
                        viewModel.startQuiz()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retake Quiz")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .foregroundColor(Theme.Colors.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(24)
                .glassCard()
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Ready to test your understanding?")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    
                    Button(action: {
                        viewModel.startQuiz()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Quiz")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                }
                .padding(24)
                .glassCard()
            }
        }
    }
}

// MARK: - Word Chip

struct WordChip: View {
    let word: WordEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word.word ?? "")
                .font(.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
            
            Text(word.translation ?? "")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.divider, lineWidth: 1)
        )
    }
}

#Preview {
    StoryReadingView(viewModel: StoryViewModel(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared)
    ))
}
