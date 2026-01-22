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
    let wordRepository: WordRepository
    let userManager = UserManager.shared
    let translationService = TranslationService.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    init() {
        self.wordRepository = WordRepository(dataManager: dataManager)
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                ContentView(
                    dataManager: dataManager,
                    wordRepository: wordRepository,
                    userManager: userManager,
                    translationService: translationService
                )
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
        wordRepository.refresh()
        NotificationManager.shared.updateNotificationsAndBadge(
            dueCount: wordRepository.dueWords().count,
            hour: dataManager.notificationHour,
            minute: dataManager.notificationMinute,
            notificationsEnabled: notificationsEnabled
        )
    }
}
