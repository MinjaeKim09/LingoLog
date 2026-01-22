import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
final class WordListViewModel: ObservableObject {
    @Published var selectedLanguage: String = "All"
    @Published var searchText: String = ""
    @Published private(set) var availableLanguages: [String] = ["All"]
    @Published private(set) var filteredWords: [WordDisplayModel] = []
    
    /// Flag to suppress refresh during explicit delete operations
    private(set) var isDeleting = false
    
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
    
    func updateFilteredWords() {
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
    
    func deleteWords(at offsets: IndexSet, dataManager: DataManager) {
        // Capture objectIDs BEFORE mutating data
        let objectIDsToDelete = offsets.map { filteredWords[$0].objectID }
        
        // 1. Optimistically remove from UI immediately
        withAnimation(.easeInOut(duration: 0.25)) {
            optimisticDelete(objectIDs: objectIDsToDelete)
        }
        
        // 2. Persist to Core Data
        Task {
            wordRepository.suppressRefresh(true)
            for objectID in objectIDsToDelete {
                if let wordEntry = wordRepository.wordEntry(for: objectID) {
                    dataManager.deleteWord(wordEntry)
                }
            }
            
            // 3. Wait for Core Data to settle before allowing refresh
            try? await Task.sleep(for: .milliseconds(300))
            wordRepository.suppressRefresh(false)
            commitDelete()
        }
    }
}
