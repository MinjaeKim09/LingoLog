import SwiftUI
import CoreData

struct WordListView: View {
    let dataManager: DataManager
    let translationService: TranslationService
    let wordRepository: WordRepository
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    @ObservedObject var storeManager: StoreManager
    @StateObject private var viewModel: WordListViewModel
    @State private var showingAddWord = false
    @State private var wordToEditID: NSManagedObjectID?
    @State private var showingLanguageSpaces = false
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        translationService: TranslationService,
        languageSpaceManager: LanguageSpaceManager,
        storeManager: StoreManager
    ) {
        self.dataManager = dataManager
        self.translationService = translationService
        self.wordRepository = wordRepository
        self.languageSpaceManager = languageSpaceManager
        self.storeManager = storeManager
        _viewModel = StateObject(wrappedValue: WordListViewModel(
            wordRepository: wordRepository,
            languageSpaceManager: languageSpaceManager
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your \(languageSpaceManager.activeSpace?.learningLanguageName ?? "") words")
                        .font(.system(size: 38, weight: .regular))
                        .tracking(-1)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(.horizontal)
                    if let space = languageSpaceManager.activeSpace {
                        LanguageSpaceSwitcher(space: space) {
                            showingLanguageSpaces = true
                        }
                        .padding(.horizontal)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        TextField("Search words...", text: $viewModel.searchText)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.divider, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Theme.Colors.background.opacity(0.5)) // Slight separation for header
                
                // Word List
                List {
                    ForEach(viewModel.filteredWords) { word in
                        Button {
                            wordToEditID = word.objectID
                        } label: {
                            WordRowView(word: word)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = viewModel.filteredWords.firstIndex(where: { $0.id == word.id }) {
                                    viewModel.deleteWords(at: IndexSet(integer: index), dataManager: dataManager)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWord = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView(
                    dataManager: dataManager,
                    translationService: translationService,
                    languageSpaceManager: languageSpaceManager
                )
            }
            .sheet(isPresented: Binding(
                get: { wordToEditID != nil },
                set: { if !$0 { wordToEditID = nil } }
            )) {
                if let objectID = wordToEditID,
                   let wordEntry = wordRepository.wordEntry(for: objectID) {
                    EditWordView(word: wordEntry, dataManager: dataManager)
                }
            }
            .sheet(isPresented: $showingLanguageSpaces) {
                LanguageSpacesView(
                    languageSpaceManager: languageSpaceManager,
                    storeManager: storeManager,
                    translationService: translationService
                )
            }
        }
    }
}

struct WordRowView: View {
    let word: WordDisplayModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Theme.Typography.title(word.word)
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Theme.Typography.body(word.translation)
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

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        WordListView(
            wordRepository: WordRepository(dataManager: DataManager.shared),
            dataManager: DataManager.shared,
            translationService: TranslationService.shared,
            languageSpaceManager: LanguageSpaceManager.shared,
            storeManager: StoreManager.shared
        )
    }
}
