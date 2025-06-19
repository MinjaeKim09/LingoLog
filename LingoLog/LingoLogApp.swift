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
            ContentView()
                .environmentObject(dataManager)
                .onAppear {
                    updateNotificationsAndBadge()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active || newPhase == .background {
                updateNotificationsAndBadge()
            }
        }
    }
    
    private func updateNotificationsAndBadge() {
        let dueCount = dataManager.fetchWordsDueForReview().count
        NotificationManager.shared.updateAppBadge(dueCount: dueCount)
        NotificationManager.shared.scheduleDailyDueWordsNotification(dueCount: dueCount, hour: 9, minute: 0)
    }
}
