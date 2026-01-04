import SwiftUI

struct DashboardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var showingAddWord = false
    @State private var showingQuiz = false
    @State private var showingOnboarding = false
    
    // Note: Removed logoGradient in favor of Theme colors
    
    private var totalWords: Int {
        dataManager.fetchWords().count
    }
    
    private var masteredWords: Int {
        dataManager.fetchWords().filter { $0.isMastered }.count
    }
    
    private var wordsDueForReview: Int {
        dataManager.fetchWordsDueForReview().count
    }
    
    private var learningStreak: Int {
        // Simple streak calculation - can be enhanced later
        let words = dataManager.fetchWords()
        let today = Calendar.current.startOfDay(for: Date())
        let wordsReviewedToday = words.filter { word in
            guard let lastReviewed = word.lastReviewed else { return false }
            return Calendar.current.isDate(lastReviewed, inSameDayAs: today)
        }.count
        
        return wordsReviewedToday > 0 ? 1 : 0 // Simplified for now
    }
    
    private var notificationTimeString: String {
        let comps = DateComponents(hour: dataManager.notificationHour, minute: dataManager.notificationMinute)
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                            subtitle: "\(wordsDueForReview) words due",
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
                            value: "\(totalWords)",
                            icon: "book.fill"
                        )
                        StatCard(
                            title: "Mastered Words",
                            value: "\(masteredWords)",
                            icon: "star.fill"
                        )
                        StatCard(
                            title: "Due for Review",
                            value: "\(wordsDueForReview)",
                            icon: "clock.fill"
                        )
                        StatCard(
                            title: "Learning Streak",
                            value: "\(learningStreak) day\(learningStreak == 1 ? "" : "s")",
                            icon: "flame.fill"
                        )
                    }
                    
                    // Recent Words
                    if !dataManager.fetchWords().isEmpty {
                        RecentWordsSection()
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
                AddWordView()
            }
            .sheet(isPresented: $showingQuiz) {
                QuizView()
            }
            .sheet(isPresented: $showingOnboarding) {
                NameOnboardingView()
            }
        }
        .onAppear {
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
                    .font(.title)
                    .foregroundStyle(Theme.Colors.accent)
                
                VStack(spacing: 4) {
                    Theme.Typography.title(title)
                        .font(.headline) // Override size slightly for button context
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Theme.Typography.body(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
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
    @ObservedObject var dataManager = DataManager.shared
    
    private var recentWords: [WordEntry] {
        Array(dataManager.fetchWords().prefix(5))
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
                                .fill(index < Int(word.masteryLevel) ? Theme.Colors.success : Color.gray.opacity(0.3))
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
        DashboardView()
    }
} 