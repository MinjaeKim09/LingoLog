import SwiftUI

/// A compact entry point for changing the app-wide learning context.
struct LanguageSpaceSwitcher: View {
    let space: LanguageSpace
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(space.learningLanguageCode.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .padding(.horizontal, 6)
                    .frame(minHeight: 22)
                    .foregroundStyle(.white)
                    .background(Theme.Colors.accentField, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(space.learningLanguageName)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(Theme.Colors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Colors.accentSurface)
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
                        PageHeader(
                            "Language spaces",
                            subtitle: "Keep each language’s words, practice, and stories together."
                        )
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
                        Label("Add language space", systemImage: "plus")
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
            .background(AmbientBackground())
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
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeader(
                            isInitialSetup ? "Choose a language" : "New language space",
                            subtitle: isInitialSetup
                                ? "Pick what you want to learn and the language you want meanings in."
                                : "Words, practice, and stories here stay separate from your other languages."
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Label("I’m learning", systemImage: "character.book.closed.fill")
                                .font(.headline)
                            languageButton(title: learningLanguageName) {
                                showingLearningLanguagePicker = true
                            }
                        }
                        .padding()
                        .glassCard()

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Show meanings in", systemImage: "text.bubble.fill")
                                .font(.headline)
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

                        Button(isInitialSetup ? "Start learning" : "Create space") {
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
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
