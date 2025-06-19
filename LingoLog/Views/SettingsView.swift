import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
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
            List {
                Section("Statistics") {
                    HStack {
                        Text("Total Words")
                        Spacer()
                        Text("\(dataManager.fetchWords().count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Mastered Words")
                        Spacer()
                        Text("\(dataManager.fetchWords().filter { $0.isMastered }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Words Due for Review")
                        Spacer()
                        Text("\(dataManager.fetchWordsDueForReview().count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Languages") {
                    ForEach(dataManager.getAvailableLanguages(), id: \.self) { language in
                        HStack {
                            Text(language)
                            Spacer()
                            Text("\(dataManager.fetchWords(for: language).count) words")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Enable Daily Notifications")
                    }
                    .onChange(of: notificationsEnabled) { _ in
                        updateNotificationsAndBadge()
                    }
                    if notificationsEnabled {
                        DatePicker(
                            "Daily Reminder Time",
                            selection: Binding(get: { notificationTime }, set: { setNotificationTime($0) }),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        showingExportSheet = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset All Data") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(.blue)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
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
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your vocabulary data will be exported as a CSV file that you can open in Excel, Google Sheets, or any spreadsheet application.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("\(dataManager.fetchWords().count) words")
                            .font(.headline)
                    }
                    
                    Text("Ready to export")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                ShareLink(
                    item: exportData,
                    preview: SharePreview(
                        "LingoLog Vocabulary Export",
                        image: "doc.text"
                    )
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 