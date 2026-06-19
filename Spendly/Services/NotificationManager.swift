//
//  NotificationManager.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Notification permission: \(granted)")
        }
    }
    
    func scheduleRecurringNotification(for expense: RecurringExpense) {
        let content = UNMutableNotificationContent()
        content.title = "Bill Reminder 💸"
        content.body = "Your \(expense.title) payment of $\(String(format: "%.2f", expense.amount)) is due today. Did it go through?"
        content.sound = .default
        content.userInfo = ["expenseId": expense.id.uuidString]
        
        var trigger: UNCalendarNotificationTrigger
        
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        
        switch expense.frequency {
        case .monthly:
            components.day = expense.dayOfMonth ?? 1
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .weekly:
            components.weekday = expense.dayOfWeek ?? 2
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .biweekly:
            components.day = expense.dayOfMonth ?? 1
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let request = UNNotificationRequest(
            identifier: expense.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
