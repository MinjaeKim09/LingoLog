import SwiftUI

struct StoryHistoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.storyHistory.isEmpty {
                        emptyStateView
                    } else {
                        // Language Filter
                        languageFilterSection
                        
                        // Stories List
                        storiesListSection
                    }
                    
                    Spacer(minLength: 50)
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
                    Theme.Typography.title("Story History")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondaryAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 40))
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
    
    // MARK: - Language Filter Section
    
    private var languageFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: viewModel.selectedLanguage.isEmpty
                    ) {
                        viewModel.selectedLanguage = ""
                    }
                    
                    ForEach(viewModel.storyLanguages, id: \.self) { language in
                        FilterChip(
                            title: language,
                            isSelected: viewModel.selectedLanguage == language
                        ) {
                            viewModel.selectedLanguage = language
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Stories List Section
    
    private var storiesListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.storyHistory) { story in
                StoryHistoryCard(story: story) {
                    viewModel.selectStory(story)
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.accent : Theme.Colors.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Theme.Colors.accent : Theme.Colors.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
        .buttonStyle(.plain)
    }
}

#Preview {
    StoryHistoryView(viewModel: StoryViewModel(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared)
    ))
}
