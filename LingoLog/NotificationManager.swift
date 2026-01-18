import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                AppLogger.notifications.error("Notification permission error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func ensureAuthorization(completion: @escaping (Bool, UNAuthorizationStatus) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    center.getNotificationSettings { updated in
                        completion(granted, updated.authorizationStatus)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                completion(true, settings.authorizationStatus)
            case .denied:
                completion(false, settings.authorizationStatus)
            @unknown default:
                completion(false, settings.authorizationStatus)
            }
        }
    }
    
    func scheduleDailyDueWordsNotification(dueCount: Int, hour: Int = 9, minute: Int = 0) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dueWordsNotification"])
        guard dueCount > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Words Due for Review"
        content.body = "You have \(dueCount) word\(dueCount == 1 ? "" : "s") to review today!"
        content.sound = .default
        content.badge = NSNumber(value: dueCount)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dueWordsNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func updateAppBadge(dueCount: Int) {
        UNUserNotificationCenter.current().setBadgeCount(dueCount) { error in
            if let error = error {
                AppLogger.notifications.error("Error setting badge count: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                AppLogger.notifications.error("Error clearing badge count: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func updateNotificationsAndBadge(
        dueCount: Int,
        hour: Int,
        minute: Int,
        notificationsEnabled: Bool
    ) {
        if notificationsEnabled {
            updateAppBadge(dueCount: dueCount)
            scheduleDailyDueWordsNotification(
                dueCount: dueCount,
                hour: hour,
                minute: minute
            )
        } else {
            clearBadge()
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["dueWordsNotification"])
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
} 