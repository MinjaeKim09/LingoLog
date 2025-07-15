import SwiftUI

struct WordListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedLanguage: String = "All"
    @State private var showingAddWord = false
    @State private var searchText = ""
    
    // Logo-inspired gradient
    private let logoGradient = LinearGradient(
        colors: [Color.cyan, Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
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
                // Language Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableLanguages, id: \.self) { language in
                            LanguageFilterButton(
                                language: language,
                                isSelected: selectedLanguage == language,
                                gradient: logoGradient
                            ) {
                                selectedLanguage = language
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(logoGradient)
                    TextField("Search words...", text: $searchText)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Word List
                List {
                    ForEach(filteredWords, id: \.id) { word in
                        WordRowView(word: word, gradient: logoGradient)
                            .listRowBackground(Color(.systemGray6))
                    }
                    .onDelete(perform: deleteWords)
                }
                .listStyle(PlainListStyle())
                .background(Color(.systemGray6))
            }
            .background(Color(.systemGray6))
            .navigationTitle("My Words")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWord = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(logoGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
        }
    }
    
    private func deleteWords(offsets: IndexSet) {
        for index in offsets {
            let word = filteredWords[index]
            dataManager.deleteWord(word)
        }
    }
}

struct WordRowView: View {
    let word: WordEntry
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.word ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(word.translation ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(word.language ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index < Int(word.masteryLevel) ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            if let context = word.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            HStack {
                if let dateAdded = word.dateAdded {
                    Text("Added \(dateAdded.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if word.reviewCount > 0 {
                    Text("Reviewed \(word.reviewCount) times")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray5))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(gradient, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}

struct LanguageFilterButton: View {
    let language: String
    let isSelected: Bool
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(language)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? gradient : LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(gradient, lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct TextLabel: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.caption2)
            .foregroundColor(.gray)
    }
}

#Preview {
    WordListView()
} 