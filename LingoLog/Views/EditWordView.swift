import SwiftUI
import UIKit

struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var word: WordEntry
    let dataManager: DataManager
    @State private var editedWord = ""
    @State private var editedTranslation = ""
    @State private var editedContext = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PageHeader("Edit word", subtitle: "Keep both sides clear and memorable.")
                        EditField(title: "Word or phrase", icon: "character.cursor.ibeam", text: $editedWord)
                        EditField(title: "Meaning", icon: "text.bubble", text: $editedTranslation)
                        EditField(title: "Memory cue", icon: "quote.bubble", text: $editedContext, optional: true)
                    }
                    .padding(Theme.Metrics.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(editedWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        word.word = editedWord.trimmingCharacters(in: .whitespacesAndNewlines)
        word.translation = editedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = editedContext.trimmingCharacters(in: .whitespacesAndNewlines)
        word.context = context.isEmpty ? nil : context
        dataManager.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

private struct EditField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var optional = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon).font(.headline)
                Spacer()
                if optional { Text("Optional").font(.caption).foregroundStyle(Theme.Colors.textSecondary) }
            }
            TextField(title, text: $text, axis: .vertical)
                .lineLimit(1...4)
                .padding(15)
                .background(Theme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(18)
        .glassCard()
    }
}
