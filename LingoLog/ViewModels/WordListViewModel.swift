import Combine
import Foundation

@MainActor
final class WordListViewModel: ObservableObject {
    @Published var selectedLanguage: String = "All"
    @Published var searchText: String = ""
    @Published private(set) var availableLanguages: [String] = ["All"]
    @Published private(set) var filteredWords: [WordEntry] = []
    
    private let wordRepository: WordRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
        bind()
        refresh()
    }
    
    func refresh() {
        availableLanguages = ["All"] + wordRepository.availableLanguages()
        updateFilteredWords()
    }
    
    private func bind() {
        wordRepository.$words
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
        let words = wordRepository.words(for: selectedLanguage == "All" ? nil : selectedLanguage)
        guard !searchText.isEmpty else {
            filteredWords = words
            return
        }
        
        let query = searchText
        filteredWords = words.filter { word in
            (word.word?.localizedCaseInsensitiveContains(query) ?? false) ||
            (word.translation?.localizedCaseInsensitiveContains(query) ?? false) ||
            (word.context?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}
