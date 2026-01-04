import SwiftUI
import Combine
import Translation

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var inputText = ""
    @AppStorage("lastUsedSourceLanguage") private var sourceLanguage = "en"
    @State private var translation: String? = nil
    @AppStorage("lastUsedTargetLanguage") private var targetLanguage = "en"
    @State private var context = ""
    @State private var isTranslating = false
    @State private var errorMessage: String? = nil
    @State private var debounceCancellable: AnyCancellable? = nil
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var textToTranslate: String = ""
    
    private let languageOptions = [
        (code: "en", name: "English"),
        (code: "ko", name: "Korean"),
        (code: "ja", name: "Japanese"),
        (code: "zh", name: "Chinese"),
        (code: "es", name: "Spanish"),
        (code: "fr", name: "French"),
        (code: "de", name: "German"),
        (code: "it", name: "Italian"),
        (code: "pt", name: "Portuguese"),
        (code: "ru", name: "Russian"),
        (code: "ar", name: "Arabic")
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Word or Phrase")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Type or paste here", text: $inputText)
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                                .onChange(of: inputText) { _, newValue in
                                    debounceCancellable?.cancel()
                                    debounceCancellable = Just(newValue)
                                        .delay(for: .milliseconds(500), scheduler: RunLoop.main)
                                        .sink { value in
                                            translate(text: value)
                                        }
                                }
                        }
                        .padding()
                        .glassCard()
                        
                        // Languages Section
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Theme.Typography.body("Translate From")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                    
                                    Picker("Source", selection: $sourceLanguage) {
                                        ForEach(languageOptions, id: \.code) { lang in
                                            Text(lang.name).tag(lang.code)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .accentColor(Theme.Colors.accent)
                                    .padding(.horizontal, 8)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(Theme.Colors.textSecondary)
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Theme.Typography.body("Translate To")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                    
                                    Picker("Target", selection: $targetLanguage) {
                                        ForEach(languageOptions, id: \.code) { lang in
                                            Text(lang.name).tag(lang.code)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .accentColor(Theme.Colors.accent)
                                    .padding(.horizontal, 8)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .glassCard()
                        
                        // Status & Result
                        if isTranslating {
                            HStack(spacing: 12) {
                                ProgressView()
                                Theme.Typography.body("Translating...")
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassCard()
                        }
                        
                        if let translated = translation, !translated.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Theme.Typography.title("Translation")
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text(translated)
                                    .font(.system(.title3, design: .serif))
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Theme.Colors.accent.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding()
                            .glassCard()
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(Theme.Colors.error)
                                .font(.caption)
                                .padding()
                                .glassCard()
                        }
                        
                        // Context Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Context (Optional)")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Where did you see this? (e.g., K-drama)", text: $context)
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .autocapitalization(.sentences)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                        }
                        .padding()
                        .glassCard()
                    }
                    .padding()
                }
                .navigationTitle("Add New Word")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            if let translated = translation, !translated.isEmpty {
                                saveTranslation(translated: translated)
                            }
                        } label: {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                        .disabled(translation == nil || translation?.isEmpty == true)
                        .foregroundStyle(translation == nil || translation?.isEmpty == true ? Color.gray : Theme.Colors.accent)
                    }
                }
            }
            .navigationViewStyle(.stack)
        }
        .translationTask(translationConfiguration) { session in
            do {
                let response = try await session.translate(textToTranslate)
                await MainActor.run {
                    self.translation = response.targetText
                    self.isTranslating = false
                }
            } catch {
                await MainActor.run {
                    self.translation = nil
                    self.errorMessage = "Translation failed: \(error.localizedDescription)"
                    self.isTranslating = false
                }
            }
        }
    }
    
    private func translate(text: String) {
        guard !text.isEmpty else {
            translation = nil
            isTranslating = false
            return
        }
        
        isTranslating = true
        errorMessage = nil
        textToTranslate = text
        
        if translationConfiguration == nil {
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: Locale.Language(identifier: targetLanguage)
            )
        } else {
            translationConfiguration?.invalidate()
        }
    }
    
    private func saveTranslation(translated: String) {
        dataManager.addWord(
            word: inputText,
            translation: translated,
            language: targetLanguage,
            context: context.isEmpty ? nil : context
        )
        dismiss()
    }
}

#Preview {
    AddWordView()
} 
