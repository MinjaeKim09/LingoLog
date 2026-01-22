import Combine
import CoreData
import Foundation

@MainActor
final class WordListViewModel: ObservableObject {
    @Published var selectedLanguage: String = "All"
    @Published var searchText: String = ""
    @Published private(set) var availableLanguages: [String] = ["All"]
    @Published private(set) var filteredWords: [WordDisplayModel] = []
    
    private let wordRepository: WordRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
        bind()
        refresh()
    }
    
    /// Get the managed WordEntry for a given objectID (for delete operations)
    func wordEntry(for objectID: NSManagedObjectID) -> WordEntry? {
        wordRepository.wordEntry(for: objectID)
    }
    
    func refresh() {
        availableLanguages = ["All"] + wordRepository.availableLanguages()
        updateFilteredWords()
    }
    
    private func bind() {
        wordRepository.$displayModels
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest($selectedLanguage, $searchText)
            .sink { [weak self] _, _ in
                self?.updateFilteredWords()
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredWords() {
        let words = wordRepository.displayModels(for: selectedLanguage == "All" ? nil : selectedLanguage)
        guard !searchText.isEmpty else {
            filteredWords = words
            return
        }
        
        let query = searchText
        filteredWords = words.filter { word in
            word.word.localizedCaseInsensitiveContains(query) ||
            word.translation.localizedCaseInsensitiveContains(query) ||
            (word.context?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}
