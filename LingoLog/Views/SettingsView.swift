import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var userManager: UserManager
    @ObservedObject var storeManager: StoreManager
    let wordRepository: WordRepository
    let translationService: TranslationService
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var showingNotificationSettingsAlert = false
    @State private var showingLanguageRepair = false
    @State private var showingLanguageSpaces = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        userManager: UserManager,
        storeManager: StoreManager = .shared,
        translationService: TranslationService = .shared,
        languageSpaceManager: LanguageSpaceManager
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.userManager = userManager
        self.storeManager = storeManager
        self.translationService = translationService
        self.languageSpaceManager = languageSpaceManager
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            wordRepository: wordRepository,
            languageSpaceManager: languageSpaceManager
        ))
    }
    
    var notificationTime: Date {
        var components = DateComponents()
        components.hour = dataManager.notificationHour
        components.minute = dataManager.notificationMinute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private func setNotificationTime(_ newValue: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
        dataManager.notificationHour = comps.hour ?? 9
        dataManager.notificationMinute = comps.minute ?? 0
        updateNotificationsAndBadge()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: 24) {
                    PageHeader("More", subtitle: "Shape LingoLog around the way you learn.")
                    
                    // Profile Section
                    profileSection
                    
                    // Purchases Section
                    purchasesSection

#if DEBUG
                    developerSection
#endif
                    
                    // Active Space Section
                    SettingsSection(title: "Learning Space") {
                        if let space = languageSpaceManager.activeSpace {
                            Button(action: { showingLanguageSpaces = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "character.book.closed.fill")
                                        .foregroundStyle(Theme.Colors.accent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Theme.Typography.body(space.learningLanguageName)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                        Text(space.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider().background(Theme.Colors.divider)
                        }

                        VStack(spacing: 8) {
                            StatisticsRow(title: "Total Words", value: "\(viewModel.totalWords)")
                            Divider().background(Theme.Colors.divider)
                            StatisticsRow(title: "Mastered Words", value: "\(viewModel.masteredWords)")
                            Divider().background(Theme.Colors.divider)
                            StatisticsRow(title: "Words Due for Review", value: "\(viewModel.wordsDueForReview)")
                        }
                    }
                    
                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        Toggle(isOn: $notificationsEnabled) {
                            Theme.Typography.body("Enable Daily Notifications")
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.accent))
                        .onChange(of: notificationsEnabled) { _, _ in
                            handleNotificationToggle()
                        }
                        
                        if notificationsEnabled {
                            Divider().background(Theme.Colors.divider)
                            HStack {
                                Theme.Typography.body("Daily Reminder Time")
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: Binding(get: { notificationTime }, set: { setNotificationTime($0) }),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .tint(Theme.Colors.accent)
                            }
                        }
                    }
                    
                    // Data Management Section
                    SettingsSection(title: "Data Management") {
                        Button(action: { showingExportSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Theme.Typography.body("Export Data")
                            }
                            .foregroundColor(Theme.Colors.accent)
                        }

                        Divider().background(Theme.Colors.divider)

                        Button(action: { showingLanguageRepair = true }) {
                            HStack {
                                Image(systemName: "character.book.closed")
                                Theme.Typography.body("Correct Vocabulary Language")
                            }
                            .foregroundColor(Theme.Colors.accent)
                        }
                        
                        Divider().background(Theme.Colors.divider)
                        
                        Button(action: { showingResetAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Theme.Typography.body("Reset All Data")
                            }
                            .foregroundColor(Theme.Colors.error)
                        }
                    }
                    
                    // About Section
                    SettingsSection(title: "About") {
                        HStack {
                            Theme.Typography.body("Version")
                            Spacer()
                            Text(appVersion)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    
                    // Footer Links
                    VStack(spacing: 12) {
                        if let privacyURL = AppConfig.privacyPolicyURL {
                            Link("Privacy Policy", destination: privacyURL)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        if let termsURL = AppConfig.termsOfServiceURL {
                            Link("Terms of Service", destination: termsURL)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    .padding(.top, 8)
                    }
                    .padding(Theme.Metrics.pagePadding)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your words and progress. This action cannot be undone.")
            }
            .alert("Notifications Disabled", isPresented: $showingNotificationSettingsAlert) {
                Button("Open Settings") {
                    NotificationManager.shared.openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enable notifications in Settings to receive daily reminders.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(dataManager: dataManager)
            }
            .sheet(isPresented: $showingLanguageRepair) {
                VocabularyLanguageRepairView(
                    wordRepository: wordRepository,
                    dataManager: dataManager,
                    translationService: translationService,
                    languageSpaceManager: languageSpaceManager
                )
            }
            .sheet(isPresented: $showingLanguageSpaces) {
                LanguageSpacesView(
                    languageSpaceManager: languageSpaceManager,
                    storeManager: storeManager,
                    translationService: translationService
                )
            }
        }
    }
    
    // MARK: - Profile Section
    
    @ViewBuilder
    private var profileSection: some View {
        SettingsSection(title: "Profile") {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.textSecondary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "iphone")
                            .font(.title3)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local Profile")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        
                        Text("Your vocabulary and progress are saved on this device.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                TextField("Your Name", text: $userManager.displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    // MARK: - Purchases Section
    
    @ViewBuilder
    private var purchasesSection: some View {
        SettingsSection(title: "Purchases") {
            HStack {
                Image(systemName: storeManager.isDailyStoriesActive ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(storeManager.isDailyStoriesActive ? Theme.Colors.success : Theme.Colors.textSecondary)
                
                Theme.Typography.body("Daily Stories + Spaces")
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                if storeManager.isDailyStoriesActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.success)
                } else {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            
            Divider().background(Theme.Colors.divider)
            
            Button(action: {
                Task { await storeManager.restorePurchases() }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Theme.Typography.body("Restore Purchases")
                }
                .foregroundColor(Theme.Colors.accent)
            }
            
            if storeManager.isDailyStoriesActive {
                Divider().background(Theme.Colors.divider)
                
                Button(action: {
                    Task { await storeManager.manageSubscriptions() }
                }) {
                    HStack {
                        Image(systemName: "creditcard")
                        Theme.Typography.body("Manage Subscription")
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
            
            if let error = storeManager.purchaseError {
                Divider().background(Theme.Colors.divider)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.error)
            }
        }
    }

#if DEBUG
    private var developerSection: some View {
        SettingsSection(title: "Developer") {
            Toggle(
                isOn: Binding(
                    get: { storeManager.developerDailyStoriesOverride },
                    set: { storeManager.setDeveloperDailyStoriesOverride($0) }
                )
            ) {
                VStack(alignment: .leading, spacing: 3) {
                    Theme.Typography.body("Unlock Daily Stories + Spaces")
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("Debug build only — bypasses StoreKit using the development backend.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.accent))
        }
    }
#endif
    
    // MARK: - Helpers
    
    private func resetAllData() {
        dataManager.deleteAllLearningData()
        languageSpaceManager.resetSpaces()
        StudyHistoryManager.shared.reset()
        userManager.resetProfile()
        NotificationManager.shared.updateNotificationsAndBadge(
            dueCount: 0,
            hour: dataManager.notificationHour,
            minute: dataManager.notificationMinute,
            notificationsEnabled: false
        )
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private func handleNotificationToggle() {
        if notificationsEnabled {
            NotificationManager.shared.ensureAuthorization { granted, status in
                DispatchQueue.main.async {
                    if granted {
                        updateNotificationsAndBadge()
                    } else {
                        notificationsEnabled = false
                        showingNotificationSettingsAlert = true
                    }
                }
            }
        } else {
            updateNotificationsAndBadge()
        }
    }
    
    private func updateNotificationsAndBadge() {
        NotificationManager.shared.updateNotificationsAndBadge(
            dueCount: viewModel.wordsDueForReview,
            hour: dataManager.notificationHour,
            minute: dataManager.notificationMinute,
            notificationsEnabled: notificationsEnabled
        )
    }
}

struct VocabularyLanguageRepairView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var wordRepository: WordRepository
    let dataManager: DataManager
    let translationService: TranslationService
    let languageSpaceManager: LanguageSpaceManager

    @State private var languages: [Language] = []
    @State private var currentLanguage = ""
    @State private var correctedLanguage = ""
    @State private var showingCorrectedLanguagePicker = false
    @State private var showingConfirmation = false

    private var affectedCount: Int {
        wordRepository.displayModels.filter { $0.language == currentLanguage }.count
    }

    private func languageName(for code: String) -> String {
        languages.first(where: { $0.code == code })?.name
            ?? Locale(identifier: "en").localizedString(forLanguageCode: code)
            ?? code
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Theme.Typography.body(
                        "Older LingoLog versions could label terms with the translation language. Choose a bucket and the language its terms are actually written in."
                    )
                    .foregroundStyle(Theme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently labeled")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Picker("Currently labeled", selection: $currentLanguage) {
                            ForEach(wordRepository.availableLanguages(), id: \.self) { code in
                                Text("\(languageName(for: code)) (\(code))").tag(code)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms are actually in")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Button {
                            showingCorrectedLanguagePicker = true
                        } label: {
                            HStack {
                                Text(correctedLanguage.isEmpty ? "Choose language" : languageName(for: correctedLanguage))
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Theme.Colors.inputBackground)
                            .cornerRadius(10)
                        }
                    }

                    Text("\(affectedCount) terms will move to the \(languageName(for: correctedLanguage)) practice-language bucket.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Button("Relabel \(affectedCount) Terms") {
                        showingConfirmation = true
                    }
                    .primaryButtonStyle()
                    .disabled(affectedCount == 0 || correctedLanguage.isEmpty || correctedLanguage == currentLanguage)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Correct Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCorrectedLanguagePicker) {
                LanguagePickerView(
                    selectedLanguage: $correctedLanguage,
                    title: "Learning Language",
                    languages: languages
                )
            }
            .alert("Relabel \(affectedCount) Terms?", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Relabel") {
                    dataManager.relabelWords(from: currentLanguage, to: correctedLanguage)
                    languageSpaceManager.ensureSpace(
                        learningLanguageCode: correctedLanguage,
                        preferredMeaningLanguageCode: languageSpaceManager.activeSpace?.meaningLanguageCode ?? "en"
                    )
                    wordRepository.refresh()
                    currentLanguage = wordRepository.availableLanguages().first ?? ""
                }
            } message: {
                Text("Use this only when every selected term is written in \(languageName(for: correctedLanguage)).")
            }
            .task {
                languages = (try? await translationService.fetchLanguages()) ?? []
                currentLanguage = wordRepository.availableLanguages().first ?? ""
                correctedLanguage = languageSpaceManager.activeSpace?.learningLanguageCode ?? ""
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Theme.Typography.title(title)
                .font(.headline)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding()
            .glassCard()
        }
    }
}

struct StatisticsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Theme.Typography.body(title)
                .foregroundColor(Theme.Colors.textPrimary)
            Spacer()
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    
    private var exportData: String {
        let words = dataManager.fetchWords()
        var csv = "Word,Translation,Language,Context,Date Added,Mastery Level,Review Count,Is Mastered\n"
        
        for word in words {
            let context = word.context?.replacingOccurrences(of: ",", with: ";") ?? ""
            let dateString: String
            if let date = word.dateAdded {
                dateString = date.formatted(date: .abbreviated, time: .omitted)
            } else {
                dateString = ""
            }
            csv += "\(word.word ?? ""),\(word.translation ?? ""),\(word.language ?? ""),\(context),\(dateString),\(word.masteryLevel),\(word.reviewCount),\(word.isMastered)\n"
        }
        
        return csv
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Theme.Typography.title("Export Your Data")
                            .foregroundStyle(Theme.Colors.textPrimary)
                        
                        Theme.Typography.body("Your vocabulary data will be exported as a CSV file that you can open in Excel, Google Sheets, or any spreadsheet application.")
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(Theme.Colors.accent)
                            Text("\(dataManager.fetchWords().count) words")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                        
                        Text("Ready to export")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(24)
                    .glassCard()
                    .padding(.horizontal)
                    
                    ShareLink(
                        item: exportData,
                        preview: SharePreview(
                            "LingoLog Vocabulary Export",
                            image: "doc.text"
                        )
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share / Save File")
                        }
                    }
                    .primaryButtonStyle()
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 32)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
            .navigationViewStyle(.stack)
        }
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        SettingsView(
            wordRepository: WordRepository(dataManager: DataManager.shared),
            dataManager: DataManager.shared,
            userManager: UserManager.shared,
            languageSpaceManager: LanguageSpaceManager.shared
        )
    }
}
