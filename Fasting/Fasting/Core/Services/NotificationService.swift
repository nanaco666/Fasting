//
//  NotificationService.swift
//  Fasting
//
//  本地通知：断食完成、半程提醒
//

import UserNotifications
import Foundation

enum NotificationService {
    
    // MARK: - Permission
    
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    // MARK: - Schedule
    
    /// Schedule notifications for a fasting session
    static func scheduleFastingNotifications(startTime: Date, targetDuration: TimeInterval, presetName: String) {
        let center = UNUserNotificationCenter.current()
        
        // Remove old ones
        center.removePendingNotificationRequests(withIdentifiers: ["fasting_halfway", "fasting_complete", "fasting_overtime"])
        
        let halfwayInterval = targetDuration / 2
        let halfwayDate = startTime.addingTimeInterval(halfwayInterval)
        let completeDate = startTime.addingTimeInterval(targetDuration)
        
        // Halfway
        if halfwayDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Half Way! 💪".localized
            content.body = String(format: "halfway_body".localized, presetName)
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: halfwayDate.timeIntervalSinceNow,
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "fasting_halfway", content: content, trigger: trigger))
        }
        
        // Complete
        if completeDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Goal Reached! 🎉".localized
            content.body = String(format: "complete_body".localized, presetName)
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: completeDate.timeIntervalSinceNow,
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "fasting_complete", content: content, trigger: trigger))
        }
    }
    
    /// Cancel all fasting notifications
    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["fasting_halfway", "fasting_complete", "fasting_overtime"]
        )
    }
}
