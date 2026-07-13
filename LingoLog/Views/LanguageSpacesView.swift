import SwiftUI

/// A compact entry point for changing the app-wide learning context.
struct LanguageSpaceSwitcher: View {
    let space: LanguageSpace
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption)
                Text(space.learningLanguageName)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(Theme.Colors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Colors.accent.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change language space. Current space: \(space.learningLanguageName)")
    }
}

struct FirstLanguageSpaceView: View {
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    let translationService: TranslationService

    var body: some View {
        CreateLanguageSpaceView(
            languageSpaceManager: languageSpaceManager,
            translationService: translationService,
            isInitialSetup: true
        )
    }
}

struct LanguageSpacesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    @ObservedObject var storeManager: StoreManager
    let translationService: TranslationService

    @State private var showingCreateSpace = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Theme.Typography.display("Language Spaces")
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Each space keeps its vocabulary, flashcards, and Daily Stories together.")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    VStack(spacing: 10) {
                        ForEach(languageSpaceManager.spaces) { space in
                            Button {
                                select(space)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: space.id == languageSpaceManager.activeSpaceID
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .font(.title3)
                                        .foregroundStyle(space.id == languageSpaceManager.activeSpaceID
                                                         ? Theme.Colors.accent
                                                         : Theme.Colors.textSecondary)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(space.learningLanguageName)
                                            .font(.headline)
                                            .foregroundStyle(Theme.Colors.textPrimary)
                                        Text(space.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(16)
                                .glassCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button(action: addSpace) {
                        Label("Add Language Space", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()

                    if !storeManager.isLanguageSpacesUnlocked {
                        Label("Your first learning language is free. Subscribe to add and switch between more spaces.", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingCreateSpace) {
            CreateLanguageSpaceView(
                languageSpaceManager: languageSpaceManager,
                translationService: translationService,
                isInitialSetup: false
            )
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(storeManager: storeManager)
        }
    }

    private func addSpace() {
        if storeManager.isLanguageSpacesUnlocked || languageSpaceManager.spaces.isEmpty {
            showingCreateSpace = true
        } else {
            showingPaywall = true
        }
    }

    private func select(_ space: LanguageSpace) {
        let isChangingSpace = space.id != languageSpaceManager.activeSpaceID
        if isChangingSpace,
           languageSpaceManager.spaces.count > 1,
           !storeManager.isLanguageSpacesUnlocked {
            showingPaywall = true
            return
        }
        languageSpaceManager.setActiveSpace(space)
        dismiss()
    }
}

struct CreateLanguageSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    let translationService: TranslationService
    let isInitialSetup: Bool

    @State private var learningLanguage = ""
    @State private var meaningLanguage: String
    @State private var languages: [Language] = []
    @State private var showingLearningLanguagePicker = false
    @State private var showingMeaningLanguagePicker = false
    @State private var errorMessage: String?

    init(
        languageSpaceManager: LanguageSpaceManager,
        translationService: TranslationService,
        isInitialSetup: Bool
    ) {
        self.languageSpaceManager = languageSpaceManager
        self.translationService = translationService
        self.isInitialSetup = isInitialSetup
        _meaningLanguage = State(
            initialValue: Locale.current.language.languageCode?.identifier ?? "en"
        )
    }

    private var learningLanguageName: String {
        languageName(for: learningLanguage, placeholder: "Choose language")
    }

    private var meaningLanguageName: String {
        languageName(for: meaningLanguage, placeholder: "Choose language")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Theme.Typography.display(isInitialSetup ? "Choose a language" : "New Language Space")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(isInitialSetup
                                 ? "Choose the language you want to learn. You can add another one with a Daily Stories subscription."
                                 : "Words, reviews, and stories in this space will stay separate from your other languages.")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("I’m learning")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            languageButton(title: learningLanguageName) {
                                showingLearningLanguagePicker = true
                            }
                        }
                        .padding()
                        .glassCard()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("I want meanings in")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            languageButton(title: meaningLanguageName) {
                                showingMeaningLanguagePicker = true
                            }
                        }
                        .padding()
                        .glassCard()

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.error)
                        }

                        Button(isInitialSetup ? "Start Learning" : "Create Space") {
                            createSpace()
                        }
                        .primaryButtonStyle()
                        .disabled(learningLanguage.isEmpty || meaningLanguage.isEmpty || learningLanguage == meaningLanguage)
                    }
                    .padding()
                }
            }
            .toolbar {
                if !isInitialSetup {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLearningLanguagePicker) {
            LanguagePickerView(
                selectedLanguage: $learningLanguage,
                title: "Learning Language",
                languages: languages
            )
        }
        .sheet(isPresented: $showingMeaningLanguagePicker) {
            LanguagePickerView(
                selectedLanguage: $meaningLanguage,
                title: "Meaning Language",
                languages: languages
            )
        }
        .task {
            languages = (try? await translationService.fetchLanguages()) ?? []
        }
    }

    @ViewBuilder
    private func languageButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding()
            .background(Theme.Colors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func languageName(for code: String, placeholder: String) -> String {
        guard !code.isEmpty else { return placeholder }
        return languages.first(where: { $0.code == code })?.name
            ?? Locale(identifier: "en").localizedString(forLanguageCode: code)
            ?? code
    }

    private func createSpace() {
        do {
            _ = try languageSpaceManager.addSpace(
                learningLanguageCode: learningLanguage,
                meaningLanguageCode: meaningLanguage
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
