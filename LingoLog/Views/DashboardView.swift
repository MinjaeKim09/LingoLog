import SwiftUI

struct DashboardView: View {
    @ObservedObject var userManager: UserManager
    let dataManager: DataManager
    let wordRepository: WordRepository
    let translationService: TranslationService
    @StateObject private var viewModel: DashboardViewModel
    @State private var showingAddWord = false
    @State private var showingQuiz = false
    @State private var showingOnboarding = false
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        userManager: UserManager,
        translationService: TranslationService
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.userManager = userManager
        self.translationService = translationService
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                wordRepository: wordRepository,
                dataManager: dataManager
            )
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section

                    VStack(spacing: 8) {
                        if !userManager.userName.isEmpty {
                            Theme.Typography.display("Welcome, \(userManager.userName)")
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                        } else {
                            Theme.Typography.display("Welcome to LingoLog")
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        

                    }
                    .padding(.top)
                    
                    // Quick Actions
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Add Word",
                            subtitle: "New vocabulary",
                            icon: "plus.circle.fill"
                        ) {
                            showingAddWord = true
                        }
                        
                        QuickActionButton(
                            title: "Take Quiz",
                            subtitle: "\(viewModel.wordsDueForReview) words due",
                            icon: "brain.head.profile"
                        ) {
                            showingQuiz = true
                        }
                    }
                    
                    // Statistics Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Words",
                            value: "\(viewModel.totalWords)",
                            icon: "book.fill"
                        )
                        StatCard(
                            title: "Mastered Words",
                            value: "\(viewModel.masteredWords)",
                            icon: "star.fill"
                        )
                        StatCard(
                            title: "Due for Review",
                            value: "\(viewModel.wordsDueForReview)",
                            icon: "clock.fill"
                        )
                        StatCard(
                            title: "Learning Streak",
                            value: "\(viewModel.learningStreak) day\(viewModel.learningStreak == 1 ? "" : "s")",
                            icon: "flame.fill"
                        )
                    }
                    
                    // Recent Words
                    if !wordRepository.words.isEmpty {
                        RecentWordsSection(wordRepository: wordRepository)
                    } else {
                        EmptyStateView()
                    }
                }
                .padding()
            }
            .background(Color.clear) // Allow global ZStack background to show
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWord) {
                AddWordView(
                    dataManager: dataManager,
                    translationService: translationService
                )
            }
            .sheet(isPresented: $showingQuiz) {
                QuizView(
                    wordRepository: wordRepository,
                    dataManager: dataManager
                )
            }
            .sheet(isPresented: $showingOnboarding) {
                NameOnboardingView(userManager: userManager)
            }
        }
        .onAppear {
            viewModel.refresh()
            if userManager.shouldShowOnboarding {
                showingOnboarding = true
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    // Normalize SF Symbol bounding boxes across different icons.
                    .font(.system(size: 32, weight: .regular))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Theme.Colors.accent)
                
                VStack(spacing: 4) {
                    Theme.Typography.title(title)
                        .font(.headline) // Override size slightly for button context
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Theme.Typography.body(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
            // Ensure both quick-action cards are identical height.
            .frame(height: 148)
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.secondaryAccent)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                .font(.system(.title, design: .serif))
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.textPrimary)
                
                Theme.Typography.body(title)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .glassCard()
    }
}

struct RecentWordsSection: View {
    @ObservedObject var wordRepository: WordRepository
    
    private var recentWords: [WordEntry] {
        Array(wordRepository.words.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Theme.Typography.title("Recent Words")
                .foregroundColor(Theme.Colors.textPrimary)
            
            ForEach(recentWords, id: \.id) { word in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Theme.Typography.body(word.word ?? "")
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Theme.Typography.body(word.translation ?? "")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text(word.language ?? "")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryAccent)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index < Int(word.masteryLevel) ? Theme.Colors.success : Theme.Colors.inactive)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding()
                .glassCard()
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.3))
            
            VStack(spacing: 8) {
                Theme.Typography.title("No words yet!")
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Theme.Typography.body("Start building your vocabulary by adding your first word.")
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .glassCard()
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        DashboardView(
            wordRepository: WordRepository(dataManager: DataManager.shared),
            dataManager: DataManager.shared,
            userManager: UserManager.shared,
            translationService: TranslationService.shared
        )
    }
}