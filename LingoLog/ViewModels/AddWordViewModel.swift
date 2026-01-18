import Combine
import Foundation
import SwiftUI

@MainActor
final class AddWordViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var sourceLanguage: String
    @Published var targetLanguage: String
    @Published var translation: String?
    @Published var context: String = ""
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    @Published var allLanguages: [Language] = []
    
    private let dataManager: DataManager
    private let translationService: TranslationService
    private var cancellables = Set<AnyCancellable>()
    private var translationTask: Task<Void, Never>?
    
    private let sourceLanguageKey = "lastUsedSourceLanguage"
    private let targetLanguageKey = "lastUsedTargetLanguage"
    
    init(dataManager: DataManager, translationService: TranslationService) {
        self.dataManager = dataManager
        self.translationService = translationService
        self.sourceLanguage = UserDefaults.standard.string(forKey: sourceLanguageKey) ?? "en"
        self.targetLanguage = UserDefaults.standard.string(forKey: targetLanguageKey) ?? "en"
        
        bind()
    }
    
    func loadLanguages() async {
        do {
            allLanguages = try await translationService.fetchLanguages()
        } catch {
            AppLogger.translation.error("Failed to load languages: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        
        if !inputText.isEmpty {
            translate(text: inputText)
        }
    }
    
    func saveTranslation() {
        guard let translated = translation, !translated.isEmpty else { return }
        dataManager.addWord(
            word: inputText,
            translation: translated,
            language: targetLanguage,
            context: context.isEmpty ? nil : context
        )
    }
    
    func languageName(for code: String) -> String {
        allLanguages.first(where: { $0.code == code })?.name ?? code
    }
    
    private func bind() {
        $inputText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.translate(text: value)
            }
            .store(in: &cancellables)
        
        $sourceLanguage
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self else { return }
                UserDefaults.standard.set(newValue, forKey: sourceLanguageKey)
                if !inputText.isEmpty {
                    translate(text: inputText)
                }
            }
            .store(in: &cancellables)
        
        $targetLanguage
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self else { return }
                UserDefaults.standard.set(newValue, forKey: targetLanguageKey)
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
}
