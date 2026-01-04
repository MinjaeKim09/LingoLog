import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
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
                print("Error setting badge count: \(error.localizedDescription)")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge count: \(error.localizedDescription)")
            }
        }
    }
} 