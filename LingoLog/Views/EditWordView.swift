import SwiftUI

struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var word: WordEntry
    let dataManager: DataManager
    
    @State private var editedWord: String = ""
    @State private var editedTranslation: String = ""
    @State private var editedContext: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Word Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Word")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Word", text: $editedWord)
                                .padding()
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.divider, lineWidth: 1)
                                )
                        }
                        .padding()
                        .glassCard()
                        
                        // Translation Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Translation")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Translation", text: $editedTranslation)
                                .padding()
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.divider, lineWidth: 1)
                                )
                        }
                        .padding()
                        .glassCard()
                        
                        // Context Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Context")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Context (Optional)", text: $editedContext)
                                .padding()
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
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
            }
            .navigationTitle("Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.accent)
                    .disabled(editedWord.isEmpty || editedTranslation.isEmpty)
                }
            }
            .onAppear {
                editedWord = word.word ?? ""
                editedTranslation = word.translation ?? ""
                editedContext = word.context ?? ""
            }
        }
    }
    
    private func saveChanges() {
        word.word = editedWord
        word.translation = editedTranslation
        word.context = editedContext.isEmpty ? nil : editedContext
        dataManager.save()
        dismiss()
    }
}
