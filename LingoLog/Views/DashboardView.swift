import SwiftUI

struct DashboardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddWord = false
    @State private var showingQuiz = false
    
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
                        Text("Welcome to LingoLog!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Your personal language learning companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Daily reminder at \(notificationTimeString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    // Quick Actions
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Add Word",
                            subtitle: "New vocabulary",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            showingAddWord = true
                        }
                        
                        QuickActionButton(
                            title: "Take Quiz",
                            subtitle: "\(wordsDueForReview) words due",
                            icon: "brain.head.profile",
                            color: .green
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
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Mastered",
                            value: "\(masteredWords)",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        StatCard(
                            title: "Due for Review",
                            value: "\(wordsDueForReview)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Learning Streak",
                            value: "\(learningStreak) day\(learningStreak == 1 ? "" : "s")",
                            icon: "flame.fill",
                            color: .red
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
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
            .sheet(isPresented: $showingQuiz) {
                QuizView()
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RecentWordsSection: View {
    @ObservedObject var dataManager = DataManager.shared
    
    private var recentWords: [WordEntry] {
        Array(dataManager.fetchWords().prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Words")
                .font(.title2)
                .fontWeight(.semibold)
            
            ForEach(recentWords, id: \.id) { word in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.word ?? "")
                            .font(.headline)
                        
                        Text(word.translation ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index < Int(word.masteryLevel) ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No words yet!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start building your vocabulary by adding your first word.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

#Preview {
    DashboardView()
} 