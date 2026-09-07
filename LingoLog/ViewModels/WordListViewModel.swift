import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
final class WordListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var filteredWords: [WordDisplayModel] = []
    
    /// Flag to suppress refresh during explicit delete operations
    private(set) var isDeleting = false
    
    private let wordRepository: WordRepository
    private let languageSpaceManager: LanguageSpaceManager
    private var cancellables = Set<AnyCancellable>()
    
    init(wordRepository: WordRepository, languageSpaceManager: LanguageSpaceManager) {
        self.wordRepository = wordRepository
        self.languageSpaceManager = languageSpaceManager
        bind()
        refresh()
    }
    
    /// Get the managed WordEntry for a given objectID (for delete operations)
    func wordEntry(for objectID: NSManagedObjectID) -> WordEntry? {
        wordRepository.wordEntry(for: objectID)
    }
    
    /// Optimistically remove items from the filtered list for smooth animation
    func optimisticDelete(objectIDs: [NSManagedObjectID]) {
        isDeleting = true
        filteredWords.removeAll { objectIDs.contains($0.objectID) }
    }
    
    /// Call after Core Data save completes to re-enable refresh
    func commitDelete() {
        isDeleting = false
    }
    
    func refresh() {
        guard !isDeleting else { return }
        updateFilteredWords()
    }
    
    private func bind() {
        wordRepository.$displayModels
            .combineLatest(languageSpaceManager.$activeSpaceID, $searchText)
            .sink { [weak self] words, spaceID, query in
                guard let self, !isDeleting else { return }
                updateFilteredWords(words: words, spaceID: spaceID, query: query)
            }
            .store(in: &cancellables)
    }
    
    func updateFilteredWords() {
        updateFilteredWords(
            words: wordRepository.displayModels,
            spaceID: languageSpaceManager.activeSpaceID,
            query: searchText
        )
    }

    private func updateFilteredWords(words: [WordDisplayModel], spaceID: UUID?, query: String) {
        let language = languageSpaceManager.spaces.first { $0.id == spaceID }?.learningLanguageCode
        let words = words.filter { language == nil || $0.language == language }
        guard !query.isEmpty else {
            filteredWords = words
            return
        }
        
        filteredWords = words.filter { word in
            word.word.localizedCaseInsensitiveContains(query) ||
            word.translation.localizedCaseInsensitiveContains(query) ||
            (word.context?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func deleteWords(at offsets: IndexSet, dataManager: DataManager) {
        // Capture objectIDs BEFORE mutating data
        let objectIDsToDelete = offsets.map { filteredWords[$0].objectID }
        
        // 1. Optimistically remove from UI immediately
        withAnimation(.easeInOut(duration: 0.25)) {
            optimisticDelete(objectIDs: objectIDsToDelete)
        }
        
        // Saves are synchronous on the main context. Refresh explicitly instead of
        // waiting for a notification that may have been suppressed.
        wordRepository.suppressRefresh(true)
        for objectID in objectIDsToDelete {
            if let wordEntry = wordRepository.wordEntry(for: objectID) {
                dataManager.deleteWord(wordEntry)
            }
        }
        wordRepository.suppressRefresh(false)
        wordRepository.refresh()
        commitDelete()
        refresh()
    }
}
