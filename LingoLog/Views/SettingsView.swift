import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var userManager: UserManager
    @ObservedObject var storeManager: StoreManager
    let wordRepository: WordRepository
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var showingNotificationSettingsAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingAuthSheet = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    init(wordRepository: WordRepository, dataManager: DataManager, userManager: UserManager, storeManager: StoreManager = .shared) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.userManager = userManager
        self.storeManager = storeManager
        _viewModel = StateObject(wrappedValue: SettingsViewModel(wordRepository: wordRepository))
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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Profile Section
                    profileSection
                    
                    // Purchases Section
                    purchasesSection
                    
                    // Statistics Section
                    SettingsSection(title: "Statistics") {
                        VStack(spacing: 8) {
                            StatisticsRow(title: "Total Words", value: "\(viewModel.totalWords)")
                            Divider().background(Theme.Colors.divider)
                            StatisticsRow(title: "Mastered Words", value: "\(viewModel.masteredWords)")
                            Divider().background(Theme.Colors.divider)
                            StatisticsRow(title: "Words Due for Review", value: "\(viewModel.wordsDueForReview)")
                        }
                    }
                    
                    // Languages Section
                    SettingsSection(title: "Languages") {
                        ForEach(viewModel.languageStats) { stat in
                            HStack {
                                Theme.Typography.body(stat.language)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                Text("\(stat.count) words")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            if stat.id != viewModel.languageStats.last?.id {
                                Divider().background(Theme.Colors.divider)
                            }
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
                        
                        Button(action: { showingResetAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Theme.Typography.body("Reset All Data")
                            }
                            .foregroundColor(Theme.Colors.error)
                        }
                    }
                    
                    // Account Section (if signed in)
                    if userManager.isAuthenticated {
                        SettingsSection(title: "Account") {
                            Button(action: { showingDeleteAccountAlert = true }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.xmark")
                                    Theme.Typography.body("Delete Account")
                                }
                                .foregroundColor(Theme.Colors.error)
                            }
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
                .padding()
            }
            .background(Color.clear)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Typography.title("Settings")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your words and progress. This action cannot be undone.")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    userManager.deleteAccount()
                }
            } message: {
                Text("This will delete your account and all associated data. This action cannot be undone.")
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
            .sheet(isPresented: $showingAuthSheet) {
                AuthenticationView(userManager: userManager)
            }
        }
    }
    
    // MARK: - Profile Section
    
    @ViewBuilder
    private var profileSection: some View {
        SettingsSection(title: "Profile") {
            if userManager.isAuthenticated {
                // Signed In View
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        // Provider Badge
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.accent.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: providerIcon)
                                .font(.title3)
                                .foregroundStyle(Theme.Colors.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userManager.displayName.isEmpty ? "User" : userManager.displayName)
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            
                            if let email = userManager.userEmail {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            
                            Text("Signed in with \(providerName)")
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.secondaryAccent)
                        }
                        
                        Spacer()
                    }
                    
                    Divider().background(Theme.Colors.divider)
                    
                    Button(action: {
                        userManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Theme.Typography.body("Sign Out")
                        }
                        .foregroundColor(Theme.Colors.error)
                    }
                }
            } else {
                // Guest View
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.textSecondary.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "person.fill.questionmark")
                                .font(.title3)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guest Mode")
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            
                            Text("Sign in to save your progress")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Editable name for guest
                    TextField("Your Name", text: $userManager.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Divider().background(Theme.Colors.divider)
                    
                    Button(action: {
                        showingAuthSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Theme.Typography.body("Sign In")
                        }
                        .foregroundColor(Theme.Colors.accent)
                    }
                }
            }
        }
    }
    
    // MARK: - Purchases Section
    
    @ViewBuilder
    private var purchasesSection: some View {
        SettingsSection(title: "Purchases") {
            HStack {
                Image(systemName: storeManager.isStoryUnlocked ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(storeManager.isStoryUnlocked ? Theme.Colors.success : Theme.Colors.textSecondary)
                
                Theme.Typography.body("Daily Stories")
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                if storeManager.isStoryUnlocked {
                    Text("Unlocked")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.success)
                } else {
                    Text("Locked")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            
            if !storeManager.isStoryUnlocked {
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
            }
        }
    }
    
    // MARK: - Helpers
    
    private var providerIcon: String {
        switch userManager.authProvider {
        case .apple: return "applelogo"
        case .google: return "g.circle.fill"
        default: return "person.fill"
        }
    }
    
    private var providerName: String {
        switch userManager.authProvider {
        case .apple: return "Apple"
        case .google: return "Google"
        default: return "Unknown"
        }
    }
    
    private func resetAllData() {
        for word in wordRepository.words {
            dataManager.deleteWord(word)
        }
        StudyHistoryManager.shared.reset()
        userManager.reset()
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
            userManager: UserManager.shared
        )
    }
}