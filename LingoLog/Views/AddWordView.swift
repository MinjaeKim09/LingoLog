import SwiftUI
import UIKit

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    let dataManager: DataManager
    let translationService: TranslationService
    let languageSpaceManager: LanguageSpaceManager
    @StateObject private var viewModel: AddWordViewModel
    @State private var showingContext = false
    @FocusState private var focusedField: Field?

    private enum Field { case word, context }

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
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PageHeader(
                            "Save a word",
                            subtitle: "Type in either language. We’ll work out the other side."
                        )

                        inputCard

                        if viewModel.isTranslating && viewModel.translation == nil {
                            translatingCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if let translated = viewModel.translation, !translated.isEmpty {
                            translationCard(translated)
                                .transition(.scale(scale: 0.97).combined(with: .opacity))
                        }

                        contextCard

                        if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.error)
                                .padding(.horizontal, 4)
                                .transition(.opacity)
                        }
                    }
                    .padding(Theme.Metrics.pagePadding)
                    .padding(.bottom, 100)
                    .animation(Theme.Motion.standard, value: viewModel.translation)
                    .animation(Theme.Motion.standard, value: viewModel.isTranslating)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if viewModel.saveTranslation() {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                } label: {
                    Label("Save to Words", systemImage: "checkmark")
                }
                .primaryButtonStyle()
                .disabled(!viewModel.canSave)
                .padding(.horizontal, Theme.Metrics.pagePadding)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .onAppear { focusedField = .word }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Catch a word")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                    Text(viewModel.inputLanguageName)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                if viewModel.languagePairIsValid {
                    Button {
                        withAnimation(Theme.Motion.quick) { viewModel.switchInputLanguage() }
                        focusedField = .word
                    } label: {
                        Label("Swap", systemImage: "arrow.left.arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.Colors.accent)
                    .disabled(viewModel.isTranslating)
                }
            }

            TextField("Type or paste in \(viewModel.inputLanguageName)", text: $viewModel.inputText, axis: .vertical)
                .focused($focusedField, equals: .word)
                .font(.title3.weight(.medium))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .lineLimit(2...5)
                .padding(16)
                .background(Theme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(focusedField == .word ? Theme.Colors.accent : Theme.Colors.divider.opacity(0.5), lineWidth: focusedField == .word ? 1.5 : 0.5)
                }

            if let space = viewModel.space {
                Label(space.subtitle, systemImage: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(18)
        .glassCard()
    }

    private var translatingCard: some View {
        HStack(spacing: 13) {
            ProgressView().tint(Theme.Colors.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Finding the meaning…").font(.subheadline.weight(.semibold))
                Text("This usually takes just a moment").font(.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard()
    }

    private func translationCard(_ translated: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meaning found")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                    Text(viewModel.outputLanguageName)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.Colors.success)
            }
            Text(translated)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(17)
                .background(Theme.Colors.accentSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .padding(18)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.outputLanguageName): \(translated)")
    }

    private var contextCard: some View {
        DisclosureGroup(isExpanded: $showingContext) {
            TextField("A sentence, place, or memory", text: $viewModel.context, axis: .vertical)
                .focused($focusedField, equals: .context)
                .lineLimit(2...4)
                .padding(14)
                .background(Theme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .padding(.top, 12)
        } label: {
            Label("Add a memory cue", systemImage: "quote.bubble")
                .font(.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .tint(Theme.Colors.accent)
        .padding(18)
        .glassCard()
    }
}

#Preview {
    AddWordView(
        dataManager: .shared,
        translationService: .shared,
        languageSpaceManager: .shared
    )
}
