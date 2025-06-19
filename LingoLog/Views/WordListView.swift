import SwiftUI

struct WordListView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedLanguage: String = "All"
    @State private var showingAddWord = false
    @State private var searchText = ""
    
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
                            Button(action: {
                                selectedLanguage = language
                            }) {
                                Text(language)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedLanguage == language ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedLanguage == language ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
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
                        WordRowView(word: word)
                    }
                    .onDelete(perform: deleteWords)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("My Words")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWord = true }) {
                        Image(systemName: "plus")
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
                    
                    Text(word.language ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
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
        .padding(.vertical, 4)
    }
}

#Preview {
    WordListView()
} 