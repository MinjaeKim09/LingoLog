//
//  LingoLogApp.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI
import UserNotifications
import FirebaseAppCheck
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        FirebaseApp.configure()
        return true
    }
    
}

@main
struct LingoLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let environment: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    
    init() {
        self.environment = AppEnvironment()
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        tabAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
        tabAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.18)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AmbientBackground()
                ContentView(
                    environment: environment
                )
                    .onAppear {
                        updateNotificationsAndBadge()
                    }
                    .onChange(of: environment.languageSpaceManager.activeSpaceID) { _, _ in
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
        environment.wordRepository.refresh()
        NotificationManager.shared.updateNotificationsAndBadge(
            dueCount: environment.wordRepository.dueWords(
                for: environment.languageSpaceManager.activeSpace?.learningLanguageCode
            ).count,
            hour: environment.dataManager.notificationHour,
            minute: environment.dataManager.notificationMinute,
            notificationsEnabled: notificationsEnabled
        )
    }
}
