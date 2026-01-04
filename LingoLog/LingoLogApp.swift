//
//  LingoLogApp.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI
import UserNotifications

@main
struct LingoLogApp: App {
    let dataManager = DataManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                ContentView()
                    .environmentObject(dataManager)
                    .onAppear {
                        updateNotificationsAndBadge()
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active || newPhase == .background {
                updateNotificationsAndBadge()
            }
        }
    }
    
    private func updateNotificationsAndBadge() {
        let dueCount = dataManager.fetchWordsDueForReview().count
        let notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        
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
