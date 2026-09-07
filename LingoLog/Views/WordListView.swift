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
            ZStack {
                AmbientBackground()

                VStack(spacing: 0) {
                    header

                    if viewModel.filteredWords.isEmpty {
                        emptyState
                    } else {
                        wordList
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddWord) {
                AddWordView(
                    dataManager: dataManager,
                    translationService: translationService,
                    languageSpaceManager: languageSpaceManager
                )
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: Binding(
                get: { wordToEditID != nil },
                set: { if !$0 { wordToEditID = nil } }
            )) {
                if let objectID = wordToEditID,
                   let wordEntry = wordRepository.wordEntry(for: objectID) {
                    EditWordView(word: wordEntry, dataManager: dataManager)
                        .presentationCornerRadius(28)
                }
            }
            .sheet(isPresented: $showingLanguageSpaces) {
                LanguageSpacesView(
                    languageSpaceManager: languageSpaceManager,
                    storeManager: storeManager,
                    translationService: translationService
                )
                .presentationCornerRadius(28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                PageHeader(
                    "Words",
                    subtitle: "\(viewModel.filteredWords.count) in this space"
                )
                Button {
                    showingAddWord = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accentDepth)
                            .offset(y: 3)
                        Circle()
                            .fill(Theme.Colors.accent)
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                    .padding(.bottom, 3)
                }
                .tactileButtonStyle()
                .accessibilityLabel("Add a word")
            }

            HStack(spacing: 10) {
                if let space = languageSpaceManager.activeSpace {
                    LanguageSpaceSwitcher(space: space) { showingLanguageSpaces = true }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.textSecondary)
                TextField("Search words", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 15)
            .frame(height: 48)
            .background(Theme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .padding(.horizontal, Theme.Metrics.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var wordList: some View {
        List {
            ForEach(viewModel.filteredWords) { word in
                Button {
                    wordToEditID = word.objectID
                } label: {
                    WordRowView(word: word)
                }
                .tactileButtonStyle()
                .listRowInsets(EdgeInsets(top: 4, leading: Theme.Metrics.pagePadding, bottom: 4, trailing: Theme.Metrics.pagePadding))
                .listRowSeparator(.visible)
                .listRowSeparatorTint(Theme.Colors.divider)
                .listRowBackground(Theme.Colors.background)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(word)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .animation(Theme.Motion.standard, value: viewModel.filteredWords.count)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Text(viewModel.searchText.isEmpty ? "No words yet" : "No matches")
                .font(.system(.title3, design: .rounded).weight(.bold))
        } description: {
            Text(viewModel.searchText.isEmpty
                 ? "Save your first word to begin building this language space."
                 : "Try a different spelling or phrase.")
        } actions: {
            if viewModel.searchText.isEmpty {
                Button("Save a word") { showingAddWord = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.accent)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func delete(_ word: WordDisplayModel) {
        guard let index = viewModel.filteredWords.firstIndex(where: { $0.id == word.id }) else { return }
        viewModel.deleteWords(at: IndexSet(integer: index), dataManager: dataManager)
    }
}

struct WordRowView: View {
    let word: WordDisplayModel

    private var mastery: Double {
        min(max(Double(word.masteryLevel) / 5, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.word)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(word.translation)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.top, 6)
            }

            if let context = word.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Theme.Colors.raised, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }

            HStack(spacing: 10) {
                ProgressView(value: mastery)
                    .tint(progressColor)
                Text("\(Int(word.masteryLevel))/5")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            HStack {
                if let dateAdded = word.dateAdded {
                    Text(dateAdded.formatted(date: .abbreviated, time: .omitted))
                }
                Spacer()
                if word.reviewCount > 0 {
                    Text("\(word.reviewCount) reviews")
                }
            }
            .font(.caption2)
            .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.vertical, 10)
    }

    private var progressColor: Color {
        if mastery >= 1 { return Theme.Colors.accent }
        if word.reviewCount > 0 { return Theme.Colors.violet }
        return Theme.Colors.sky
    }
}

#Preview {
    WordListView(
        wordRepository: WordRepository(dataManager: .shared),
        dataManager: .shared,
        translationService: .shared,
        languageSpaceManager: .shared,
        storeManager: .shared
    )
}
