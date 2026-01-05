import SwiftUI

struct WordListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedLanguage: String = "All"
    @State private var showingAddWord = false
    @State private var searchText = ""
    @State private var wordToEdit: WordEntry?
    
    // Note: Removed logoGradient in favor of Theme colors
    
    private var filteredWords: [WordEntry] {
        let words = dataManager.fetchWords(for: selectedLanguage == "All" ? nil : selectedLanguage)
        if searchText.isEmpty {
            return words
        } else {
            return words.filter { word in
                (word.word?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (word.translation?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (word.context?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private var availableLanguages: [String] {
        var languages = ["All"]
        languages.append(contentsOf: dataManager.getAvailableLanguages())
        return languages
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Area
                VStack(spacing: 16) {
                    // Language Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableLanguages, id: \.self) { language in
                                LanguageFilterButton(
                                    language: language,
                                    isSelected: selectedLanguage == language
                                ) {
                                    selectedLanguage = language
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        TextField("Search words...", text: $searchText)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    .padding()
                    .background(Theme.Colors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.divider, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Theme.Colors.background.opacity(0.5)) // Slight separation for header
                
                // Word List
                List {
                    ForEach(filteredWords, id: \.id) { word in
                        WordRowView(word: word)
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle()) // Make the whole row tappable
                            .onTapGesture {
                                wordToEdit = word
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            if index < filteredWords.count {
                                let wordToDelete = filteredWords[index]
                                dataManager.deleteWord(wordToDelete)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.clear)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Typography.title("My Words")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWord = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
            .sheet(item: $wordToEdit) { word in
                EditWordView(word: word)
            }
        }
    }
}

struct WordRowView: View {
    @ObservedObject var word: WordEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Theme.Typography.title(word.word ?? "")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Theme.Typography.body(word.translation ?? "")
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index < Int(word.masteryLevel) ? Theme.Colors.success : Theme.Colors.inactive)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(word.language ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.secondaryAccent.opacity(0.1))
                        .foregroundColor(Theme.Colors.secondaryAccent)
                        .cornerRadius(8)
                }
            }
            
            if let context = word.context, !context.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.accent)
                    Text(context)
                        .font(.system(.caption, design: .serif))
                        .italic()
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            
            Divider()
                .background(Theme.Colors.divider)
            
            HStack {
                if let dateAdded = word.dateAdded {
                    Text("Added \(dateAdded.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.8))
                }
                Spacer()
                if word.reviewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("\(word.reviewCount)")
                    }
                    .font(.caption2)
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.8))
                }
            }
        }
        .padding()
        .glassCard()
    }
}

struct LanguageFilterButton: View {
    let language: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(language)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Theme.Colors.accent : Theme.Colors.inputBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Theme.Colors.accent : Theme.Colors.divider, lineWidth: 1)
        )
        .shadow(color: isSelected ? Color.black.opacity(0.15) : Color.clear, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        WordListView()
    }
} 