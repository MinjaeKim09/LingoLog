import SwiftUI
import Combine
import Translation

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager = DataManager.shared
    
    // Logo-inspired gradient
    private let logoGradient = LinearGradient(
        colors: [Color.cyan, Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    @State private var inputText = ""
    @AppStorage("lastUsedSourceLanguage") private var sourceLanguage = "en" // Default to English
    @State private var translation: String? = nil
    @AppStorage("lastUsedTargetLanguage") private var targetLanguage = "en" // Default to English
    @State private var context = ""
    @State private var isTranslating = false
    @State private var errorMessage: String? = nil
    @State private var debounceCancellable: AnyCancellable? = nil
    @State private var didPrewarmNetwork = false
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var textToTranslate: String = ""
    @State private var translationTrigger: UUID = UUID()
    
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
        NavigationView {
            Form {
                Section(header: Text("Word or Phrase").foregroundStyle(logoGradient)) {
                    TextField("Type or paste here", text: $inputText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: inputText) { newValue in
                            debounceCancellable?.cancel()
                            debounceCancellable = Just(newValue)
                                .delay(for: .milliseconds(500), scheduler: RunLoop.main)
                                .sink { value in
                                    translate(text: value)
                                }
                        }
                }
                
                Section(header: Text("Translate From").foregroundStyle(logoGradient)) {
                    Picker("Source Language", selection: $sourceLanguage) {
                        ForEach(languageOptions, id: \.code) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Translate To").foregroundStyle(logoGradient)) {
                    Picker("Language", selection: $targetLanguage) {
                        ForEach(languageOptions, id: \.code) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                if isTranslating {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Translating...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let translated = translation, !translated.isEmpty {
                    Section(header: Text("Translation Result").foregroundStyle(logoGradient)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Translation")
                                Spacer()
                                Text(translated)
                                    .font(.headline)
                                    .foregroundStyle(logoGradient)
                            }
                        }
                    }
                }
                
                Section(header: Text("Context (Optional)").foregroundStyle(logoGradient)) {
                    TextField("Where did you see this? (e.g., K-drama, menu)", text: $context)
                        .autocapitalization(.sentences)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Add New Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(logoGradient)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let translated = translation, !translated.isEmpty {
                            saveTranslation(translated: translated)
                        }
                    } label: {
                        Text("Save")
                            .foregroundStyle(logoGradient)
                    }
                    .disabled(translation == nil || translation?.isEmpty == true)
                }
            }
        }
        .navigationViewStyle(.stack)
        .presentationDetents([.medium, .large])
        .onAppear {
            prewarmNetworkIfNeeded()
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
    
    private func prewarmNetworkIfNeeded() {
        // No longer needed with Apple Translation API
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
            // Create initial configuration
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: Locale.Language(identifier: targetLanguage)
            )
        } else {
            // For subsequent translations, invalidate to trigger new translation
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
    
    private func languageName(for code: String) -> String {
        if let match = languageOptions.first(where: { $0.code == code }) {
            return match.name
        }
        return code
    }
}

#Preview {
    AddWordView()
} 
