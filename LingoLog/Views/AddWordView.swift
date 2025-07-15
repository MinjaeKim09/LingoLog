import SwiftUI
import Combine

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
    @State private var detectedLanguageCode: String? = nil
    @State private var translation: String? = nil
    @State private var targetLanguage = "en" // Default to English
    @State private var context = ""
    @State private var isTranslating = false
    @State private var errorMessage: String? = nil
    @State private var debounceCancellable: AnyCancellable? = nil
    @State private var didPrewarmNetwork = false
    
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
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        .onChange(of: inputText) { newValue in
                            debounceCancellable?.cancel()
                            debounceCancellable = Just(newValue)
                                .delay(for: .milliseconds(500), scheduler: RunLoop.main)
                                .sink { value in
                                    translate(text: value)
                                }
                        }
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
                            if let detected = detectedLanguageCode {
                                HStack {
                                    Text("Detected Language")
                                    Spacer()
                                    Text(languageName(for: detected))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
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
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
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
    }
    
    private func prewarmNetworkIfNeeded() {
        guard !didPrewarmNetwork else { return }
        didPrewarmNetwork = true
        // Harmless HEAD request to prewarm network stack
        guard let url = URL(string: "https://www.google.com") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
    
    private func translate(text: String) {
        guard !text.isEmpty else {
            translation = nil
            detectedLanguageCode = nil
            return
        }
        isTranslating = true
        errorMessage = nil
        let escaped = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(targetLanguage)&dt=t&q=\(escaped)")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                self.isTranslating = false
                guard let data = data else {
                    self.translation = nil
                    self.detectedLanguageCode = nil
                    self.errorMessage = "No data received"
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let arr = json as? [Any],
                       let first = arr.first as? [Any],
                       let firstTranslation = first.first as? [Any],
                       let translated = firstTranslation.first as? String {
                        self.translation = translated
                        if arr.count > 2, let lang = arr[2] as? String {
                            self.detectedLanguageCode = lang
                        } else {
                            self.detectedLanguageCode = nil
                        }
                    } else {
                        self.translation = nil
                        self.detectedLanguageCode = nil
                        self.errorMessage = "Could not parse translation"
                    }
                } catch {
                    self.translation = nil
                    self.detectedLanguageCode = nil
                    self.errorMessage = "Translation failed: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func saveTranslation(translated: String) {
        dataManager.addWord(
            word: inputText,
            translation: translated,
            language: detectedLanguageCode ?? targetLanguage,
            context: context.isEmpty ? nil : context
        )
        dismiss()
    }
    
    private func languageName(for code: String) -> String {
        if let match = languageOptions.first(where: { $0.code == code }) {
            return match.name
        }
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}

#Preview {
    AddWordView()
} 
