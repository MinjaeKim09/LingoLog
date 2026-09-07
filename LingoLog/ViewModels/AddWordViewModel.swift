import Combine
import Foundation
import SwiftUI

@MainActor
final class AddWordViewModel: ObservableObject {
    @Published var inputText: String = "" {
        didSet { translate(text: inputText) }
    }
    @Published private(set) var space: LanguageSpace?
    @Published private(set) var inputSide: VocabularyInputSide = .learningLanguage
    @Published private(set) var translation: String?
    @Published var context: String = ""
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    private let translationService: any VocabularyTranslating
    private let translationDelay: Duration
    private let languageSpaceManager: LanguageSpaceManager
    private var cancellables = Set<AnyCancellable>()
    private var translationTask: Task<Void, Never>?
    
    init(
        dataManager: DataManager,
        translationService: any VocabularyTranslating,
        languageSpaceManager: LanguageSpaceManager,
        translationDelay: Duration = .milliseconds(500)
    ) {
        self.dataManager = dataManager
        self.translationService = translationService
        self.translationDelay = translationDelay
        self.languageSpaceManager = languageSpaceManager
        self.space = languageSpaceManager.activeSpace
        
        bind()
    }
    
    var sourceLanguage: String {
        inputSide == .learningLanguage ? learningLanguage : meaningLanguage
    }

    var targetLanguage: String {
        inputSide == .learningLanguage ? meaningLanguage : learningLanguage
    }

    var languagePairIsValid: Bool {
        !learningLanguage.isEmpty
            && !meaningLanguage.isEmpty
            && learningLanguage != meaningLanguage
    }

    var canSave: Bool {
        normalizedVocabularyPair != nil && !isTranslating
    }

    var inputLanguageName: String {
        languageName(for: sourceLanguage)
    }

    var outputLanguageName: String {
        languageName(for: targetLanguage)
    }

    var switchInputLanguageLabel: String {
        "I entered \(outputLanguageName) instead"
    }

    func switchInputLanguage() {
        let previousTranslation = translation
        inputSide = inputSide == .learningLanguage ? .meaningLanguage : .learningLanguage

        if let previousTranslation, !previousTranslation.isEmpty {
            inputText = previousTranslation
        } else {
            translate(text: inputText)
        }
    }

    @discardableResult
    func saveTranslation() -> Bool {
        guard canSave, let pair = normalizedVocabularyPair else { return false }
        dataManager.addWord(
            word: pair.term,
            translation: pair.meaning,
            language: pair.learningLanguageCode,
            context: context.isEmpty ? nil : context
        )
        return true
    }
    
    var learningLanguage: String { space?.learningLanguageCode ?? "" }

    var meaningLanguage: String { space?.meaningLanguageCode ?? "" }

    func languageName(for code: String) -> String {
        guard !code.isEmpty else { return "Language" }
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code
    }
    
    private func bind() {
        languageSpaceManager.$activeSpaceID
            .dropFirst()
            .sink { [weak self] id in
                guard let self else { return }
                space = languageSpaceManager.spaces.first { $0.id == id }
                inputSide = .learningLanguage
                translate(text: inputText)
            }
            .store(in: &cancellables)
    }
    
    private func translate(text: String) {
        translationTask?.cancel()
        // Invalidate immediately, including while the next request is debouncing.
        translation = nil
        errorMessage = nil
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                translation = nil
                isTranslating = false
            }
            return
        }

        guard languagePairIsValid else {
            translation = nil
            isTranslating = false
            errorMessage = "Choose two different languages."
            return
        }
        
        isTranslating = true
        errorMessage = nil
        
        translationTask = Task { [weak self, translationService, translationDelay, sourceLanguage, targetLanguage] in
            do {
                try await Task.sleep(for: translationDelay)
                let result = try await translationService.translate(
                    text: text,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                // Some providers finish even after cancellation. Only the latest task
                // may publish a result or change the loading state.
                try Task.checkCancellation()
                guard let self else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.translation = result
                    self.isTranslating = false
                }
            } catch {
                guard !Task.isCancelled, let self else { return }
                withAnimation {
                    self.translation = nil
                    self.errorMessage = "Translation failed: \(error.localizedDescription)"
                    self.isTranslating = false
                }
            }
        }
    }

    deinit {
        translationTask?.cancel()
    }

    private var normalizedVocabularyPair: NormalizedVocabularyPair? {
        guard let translation else { return nil }
        return NormalizedVocabularyPair.make(
            input: inputText,
            translatedText: translation,
            learningLanguageCode: learningLanguage,
            meaningLanguageCode: meaningLanguage,
            inputSide: inputSide
        )
    }
}
