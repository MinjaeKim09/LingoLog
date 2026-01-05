import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
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
                    SettingsSection(title: "Profile") {
                        TextField("Your Name", text: $userManager.userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle()) // Simple style for now, or custom
                            // Let's use a cleaner unstyled textfield with standard font
                        
                        if userManager.userName.isEmpty {
                             Text("Enter your name to personalize your experience.")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    
                    // Statistics Section
                    SettingsSection(title: "Statistics") {
                        VStack(spacing: 8) {
                            StatisticsRow(title: "Total Words", value: "\(dataManager.fetchWords().count)")
                            Divider().background(Theme.Colors.divider)
                            StatisticsRow(title: "Mastered Words", value: "\(dataManager.fetchWords().filter { $0.isMastered }.count)")
                            Divider().background(Theme.Colors.divider)
                            StatisticsRow(title: "Words Due for Review", value: "\(dataManager.fetchWordsDueForReview().count)")
                        }
                    }
                    
                    // Languages Section
                    SettingsSection(title: "Languages") {
                        ForEach(dataManager.getAvailableLanguages(), id: \.self) { language in
                            HStack {
                                Theme.Typography.body(language)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                Text("\(dataManager.fetchWords(for: language).count) words")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            // Don't add divider for the last item - simplified for now
                            if language != dataManager.getAvailableLanguages().last {
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
                            updateNotificationsAndBadge()
                        }
                        
                        if notificationsEnabled {
                            Divider().background(Theme.Colors.divider)
                            DatePicker(
                                "Daily Reminder Time",
                                selection: Binding(get: { notificationTime }, set: { setNotificationTime($0) }),
                                displayedComponents: .hourAndMinute
                            )
                            .environment(\.colorScheme, .light) // Force light style for cleaner look if needed
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
                    
                    // About Section
                    SettingsSection(title: "About") {
                        HStack {
                            Theme.Typography.body("Version")
                            Spacer()
                            Text("1.0.0")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    
                    // Footer Links
                    VStack(spacing: 12) {
                        if let privacyURL = URL(string: "https://example.com/privacy") {
                            Link("Privacy Policy", destination: privacyURL)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        if let termsURL = URL(string: "https://example.com/terms") {
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
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView()
            }
        }
    }
    
    private func resetAllData() {
        let words = dataManager.fetchWords()
        for word in words {
            dataManager.deleteWord(word)
        }
    }
    
    private func updateNotificationsAndBadge() {
        let dueCount = dataManager.fetchWordsDueForReview().count
        if notificationsEnabled {
            NotificationManager.shared.updateAppBadge(dueCount: dueCount)
            NotificationManager.shared.scheduleDailyDueWordsNotification(
                dueCount: dueCount,
                hour: dataManager.notificationHour,
                minute: dataManager.notificationMinute
            )
        } else {
            NotificationManager.shared.clearBadge()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dueWordsNotification"])
        }
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
    @ObservedObject var dataManager = DataManager.shared
    
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
        SettingsView()
    }
} 