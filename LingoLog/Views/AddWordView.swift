import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    let dataManager: DataManager
    let translationService: TranslationService
    let languageSpaceManager: LanguageSpaceManager
    @StateObject private var viewModel: AddWordViewModel

    @State private var showingContext = false

    init(
        dataManager: DataManager,
        translationService: TranslationService,
        languageSpaceManager: LanguageSpaceManager
    ) {
        self.dataManager = dataManager
        self.translationService = translationService
        self.languageSpaceManager = languageSpaceManager
        _viewModel = StateObject(
            wrappedValue: AddWordViewModel(
                dataManager: dataManager,
                translationService: translationService,
                languageSpaceManager: languageSpaceManager
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let space = viewModel.space {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(space.subtitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.Colors.accent)
                                Text("Add a term in either language. LingoLog saves it as \(space.learningLanguageName) for this space.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("\(viewModel.inputLanguageName) word or phrase")
                                .foregroundColor(Theme.Colors.textPrimary)

                            TextField(
                                "Type or paste in \(viewModel.inputLanguageName)",
                                text: $viewModel.inputText
                            )
                            .padding()
                            .background(Theme.Colors.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .font(.system(.body, design: .rounded))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.divider, lineWidth: 1)
                            )

                            Button(viewModel.switchInputLanguageLabel) {
                                viewModel.switchInputLanguage()
                            }
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.accent)
                            .disabled(viewModel.isTranslating || !viewModel.languagePairIsValid)
                        }
                        .padding()
                        .glassCard()

                        if viewModel.isTranslating && viewModel.translation == nil {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Translating…")
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .glassCard()
                        }

                        if let translated = viewModel.translation, !translated.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Theme.Typography.title("\(viewModel.outputLanguageName) \(viewModel.inputSide == .learningLanguage ? "meaning" : "term")")
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    Spacer()
                                    if viewModel.isTranslating {
                                        ProgressView().scaleEffect(0.75)
                                    }
                                }

                                Text(translated)
                                    .font(.system(.title3, design: .serif))
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Theme.Colors.accent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding()
                            .glassCard()
                        }

                        DisclosureGroup("Add context (optional)", isExpanded: $showingContext) {
                            TextField("Where did you see this?", text: $viewModel.context)
                                .padding(.top, 10)
                                .textFieldStyle(.roundedBorder)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding()
                        .glassCard()

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.error)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add \(viewModel.space?.learningLanguageName ?? "Word")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.saveTranslation() {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSave)
                    .foregroundStyle(viewModel.canSave ? Theme.Colors.accent : Color.gray)
                }
            }
        }
    }
}

#Preview {
    AddWordView(
        dataManager: DataManager.shared,
        translationService: TranslationService.shared,
        languageSpaceManager: LanguageSpaceManager.shared
    )
}
