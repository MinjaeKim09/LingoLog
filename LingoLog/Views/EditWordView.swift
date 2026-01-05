import SwiftUI

struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var word: WordEntry
    
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
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
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
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
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
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
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
        DataManager.shared.save()
        dismiss()
    }
}
