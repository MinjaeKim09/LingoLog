import SwiftUI

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: String
    let title: String
    let languages: [Language]
    
    @State private var searchText = ""
    
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
                
                if languages.isEmpty {
                    ProgressView("Loading languages...")
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
        }
    }
}
