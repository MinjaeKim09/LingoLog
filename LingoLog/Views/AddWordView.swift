import SwiftUI
import Combine


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

    @State private var showingSourcePicker = false
    @State private var showingTargetPicker = false
    @State private var allLanguages: [Language] = []
    
    // Add state for animation
    @State private var isSwapped = false
    
    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        isSwapped.toggle()
        
        // Trigger translation with new direction if there is input
        if !inputText.isEmpty {
            translate(text: inputText)
        }
    }
    
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
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.divider, lineWidth: 1)
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
                        HStack(alignment: .bottom, spacing: 12) {
                            // Translate From
                            VStack(alignment: .leading, spacing: 8) {
                                Theme.Typography.body("From")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Button(action: { showingSourcePicker = true }) {
                                    HStack {
                                        Text(getLanguageName(code: sourceLanguage))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.inputBackground)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Swap Button
                            Button(action: swapLanguages) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .foregroundColor(Theme.Colors.accent)
                                    .padding(8)
                                    .background(Theme.Colors.accent.opacity(0.1))
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(isSwapped ? 180 : 0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSwapped)
                            }
                            .padding(.bottom, 6)
                            
                            // Translate To
                            VStack(alignment: .leading, spacing: 8) {
                                Theme.Typography.body("To")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Button(action: { showingTargetPicker = true }) {
                                    HStack {
                                        Text(getLanguageName(code: targetLanguage))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.inputBackground)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .glassCard()
                        
                        // Status & Result
                        if isTranslating && translation == nil {
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
                                HStack {
                                    Theme.Typography.title("Translation")
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    if isTranslating {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                
                                Text(translated)
                                    .font(.system(.title3, design: .serif))
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Theme.Colors.accent.opacity(0.1))
                                    .cornerRadius(12)
                                    .contentTransition(.opacity)
                            }
                            .padding()
                            .glassCard()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
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
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .autocapitalization(.sentences)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.divider, lineWidth: 1)
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
            .sheet(isPresented: $showingSourcePicker) {
                LanguagePickerView(selectedLanguage: $sourceLanguage, title: "Translate From")
            }
            .sheet(isPresented: $showingTargetPicker) {
                LanguagePickerView(selectedLanguage: $targetLanguage, title: "Translate To")
            }
            .onChange(of: sourceLanguage) { _, _ in
                if !inputText.isEmpty { translate(text: inputText) }
            }
            .onChange(of: targetLanguage) { _, _ in
                if !inputText.isEmpty { translate(text: inputText) }
            }
            .task {
                do {
                    allLanguages = try await TranslationService.shared.fetchLanguages()
                } catch {
                    print("Failed to load languages: \(error)")
                }
            }
            .onAppear {
                // Reset fields or setup if needed
            }
        }

    }
    
    private func translate(text: String) {
        guard !text.isEmpty else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                translation = nil
                isTranslating = false
            }
            return
        }
        
        isTranslating = true
        errorMessage = nil
        
        
        Task {
            do {
                let result = try await TranslationService.shared.translate(
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
    
    private func saveTranslation(translated: String) {
        dataManager.addWord(
            word: inputText,
            translation: translated,
            language: targetLanguage,
            context: context.isEmpty ? nil : context
        )
        dismiss()
    }
    
    private func getLanguageName(code: String) -> String {
        return allLanguages.first(where: { $0.code == code })?.name ?? code
    }
}

#Preview {
    AddWordView()
} 
