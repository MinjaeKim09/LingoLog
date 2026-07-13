import Combine
import Foundation
import SwiftUI

@MainActor
final class AddWordViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published private(set) var space: LanguageSpace?
    @Published private(set) var inputSide: VocabularyInputSide = .learningLanguage
    @Published var translation: String?
    @Published var context: String = ""
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    private let translationService: TranslationService
    private let languageSpaceManager: LanguageSpaceManager
    private var cancellables = Set<AnyCancellable>()
    private var translationTask: Task<Void, Never>?
    
    init(
        dataManager: DataManager,
        translationService: TranslationService,
        languageSpaceManager: LanguageSpaceManager
    ) {
        self.dataManager = dataManager
        self.translationService = translationService
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
        translationTask?.cancel()
        let previousInput = inputText
        let previousTranslation = translation
        inputSide = inputSide == .learningLanguage ? .meaningLanguage : .learningLanguage

        if let previousTranslation, !previousTranslation.isEmpty {
            inputText = previousTranslation
            translation = previousInput
        }
        translate(text: inputText)
        errorMessage = nil
    }

    @discardableResult
    func saveTranslation() -> Bool {
        guard let pair = normalizedVocabularyPair else { return false }
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
        $inputText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.translate(text: value)
            }
            .store(in: &cancellables)
        
        languageSpaceManager.$activeSpaceID
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                space = languageSpaceManager.activeSpace
                inputSide = .learningLanguage
                translation = nil
                if !inputText.isEmpty {
                    translate(text: inputText)
                }
            }
            .store(in: &cancellables)
    }
    
    private func translate(text: String) {
        translationTask?.cancel()
        
        guard !text.isEmpty else {
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
        
        translationTask = Task { [sourceLanguage, targetLanguage] in
            do {
                let result = try await translationService.translate(
                    text: text,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.translation = result
                        self.isTranslating = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        self.translation = nil
                        self.errorMessage = "Translation failed: \(error.localizedDescription)"
                        self.isTranslating = false
                    }
                }
            }
        }
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
