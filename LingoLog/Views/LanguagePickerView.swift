import SwiftUI

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: String
    let title: String
    
    @State private var languages: [Language] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { lang in
                lang.name.localizedCaseInsensitiveContains(searchText) ||
                lang.nativeName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading languages...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error loading languages")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("Retry") {
                            loadLanguages()
                        }
                        .padding()
                    }
                } else {
                    List {
                        ForEach(filteredLanguages) { language in
                            Button {
                                selectedLanguage = language.code
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(language.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text(language.nativeName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if language.code == selectedLanguage {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Theme.Colors.accent)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search languages")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                loadLanguages()
            }
        }
    }
    
    private func loadLanguages() {
        guard languages.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedLanguages = try await TranslationService.shared.fetchLanguages()
                await MainActor.run {
                    self.languages = fetchedLanguages
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
