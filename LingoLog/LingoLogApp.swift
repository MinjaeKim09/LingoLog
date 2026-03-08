//
//  LingoLogApp.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI
import UserNotifications
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle Google Sign-In redirect URLs
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct LingoLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let dataManager = DataManager.shared
    let wordRepository: WordRepository
    let storyRepository: StoryRepository
    let userManager = UserManager.shared
    let translationService = TranslationService.shared
    let storeManager = StoreManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    init() {
        self.wordRepository = WordRepository(dataManager: dataManager)
        self.storyRepository = StoryRepository(dataManager: dataManager)
        NotificationManager.shared.requestAuthorization()
        
        // StoreManager is initialized via .shared above, which starts transaction listener
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                ContentView(
                    dataManager: dataManager,
                    wordRepository: wordRepository,
                    storyRepository: storyRepository,
                    userManager: userManager,
                    translationService: translationService,
                    storeManager: storeManager
                )
                    .onAppear {
                        updateNotificationsAndBadge()
                    }
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
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

