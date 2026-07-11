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
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .systemBackground
        tabAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.35)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                ContentView(
                    environment: environment
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
        environment.wordRepository.refresh()
        NotificationManager.shared.updateNotificationsAndBadge(
            dueCount: environment.wordRepository.dueWords().count,
            hour: environment.dataManager.notificationHour,
            minute: environment.dataManager.notificationMinute,
            notificationsEnabled: notificationsEnabled
        )
    }
}
