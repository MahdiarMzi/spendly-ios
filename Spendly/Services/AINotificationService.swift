//
//  AINotificationService.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//

import Foundation
import UserNotifications

class AINotificationService {
    static let shared = AINotificationService()
    private let ai = AIService()
    private let lastCheckKey = "last_proactive_check"
    
    // MARK: - Real-time check after new expense
    func checkAfterExpense(store: ExpenseStore) {
        // Only check if budget is set
        guard let remaining = store.budgetRemaining,
              let profile = store.userProfile else { return }
        
        let income = profile.incomeType == .fixed ? profile.fixedIncome : profile.currentPeriodIncome
        guard let income = income, income > 0 else { return }
        
        let pctUsed = store.total / income
        let lastExpense = store.expenses.first
        
        // Rule 1: Just went over budget
        if remaining < 0 && remaining > -50 {
            Task {
                await sendNotification(
                    title: "Over Budget! 🚨",
                    body: "You've exceeded your budget by $\(String(format: "%.2f", abs(remaining))). Time to slow down!"
                )
            }
            return
        }
        
        // Rule 2: Hit 75% of budget
        let lastCheck = UserDefaults.standard.double(forKey: "last_75_notif")
        if pctUsed >= 0.75 && pctUsed < 0.85 && lastCheck == 0 {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_75_notif")
            Task {
                await sendNotification(
                    title: "75% of Budget Used 💛",
                    body: "You have $\(String(format: "%.2f", remaining)) left for this period. Spend wisely!"
                )
            }
            return
        }
        
        // Rule 3: Single expense is more than 20% of income
        if let expense = lastExpense, expense.amount > income * 0.20 {
            Task {
                await sendNotification(
                    title: "Big Purchase Logged 👀",
                    body: "$\(String(format: "%.2f", expense.amount)) on \(expense.category.rawValue) — that's \(Int(expense.amount / income * 100))% of your income!"
                )
            }
            return
        }
    }
    // MARK: - Scheduled twice-weekly check
    func scheduleWeeklyChecks() {
        // Monday at 9am (weekday 2) and Thursday at 9am (weekday 5)
        scheduleCheck(weekday: 2, hour: 9, identifier: "monday_check")
        scheduleCheck(weekday: 5, hour: 9, identifier: "thursday_check")
    }
    
    private func scheduleCheck(weekday: Int, hour: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Spendly Weekly Check 💸"
        content.body = "Tap to see your spending insights"
        content.sound = .default
        content.userInfo = ["type": "weekly_check"]
        
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - AI Analysis
    func analyzeAndNotify(store: ExpenseStore, trigger: String) async {
        guard !store.expenses.isEmpty else { return }
        
        // Don't spam — max once per hour for real-time checks
        if trigger == "new_expense" {
            let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
            let now = Date().timeIntervalSince1970
            if now - lastCheck < 3600 { return }
            UserDefaults.standard.set(now, forKey: lastCheckKey)
        }
        
        let prompt = buildAnalysisPrompt(store: store, trigger: trigger)
        
        do {
            let response = try await ai.sendMessage(
                messages: [["role": "user", "content": prompt]],
                system: buildAnalysisSystem()
            )
            
            // Parse AI response
            let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = cleaned.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let shouldNotify = json["notify"] as? Bool,
               shouldNotify,
               let title = json["title"] as? String,
               let body = json["body"] as? String {
                await sendNotification(title: title, body: body)
            }
        } catch {
            print("AI notification check failed: \(error)")
        }
    }
    
    private func buildAnalysisSystem() -> String {
        return """
        You are a financial analysis AI. Analyze spending data and decide if a notification is warranted.
        Respond ONLY with JSON in this exact format:
        {"notify": true, "title": "Short title", "body": "Helpful message under 100 chars"}
        or
        {"notify": false, "title": "", "body": ""}
        
        Only notify if something is genuinely important:
        - Spent over 75% of budget
        - One category is over 50% of total spending
        - On track to significantly overspend
        - Unusual spike in spending
        - Week 2 spending much higher than week 1
        Do NOT notify for normal spending. No markdown. Be concise and friendly.
        """
    }
    
    private func buildAnalysisPrompt(store: ExpenseStore, trigger: String) -> String {
        let categoryBreakdown = Category.allCases
            .filter { store.total(for: $0) > 0 }
            .map { "\($0.rawValue): $\(String(format: "%.2f", store.total(for: $0)))" }
            .joined(separator: ", ")
        
        let budgetInfo: String
        if let remaining = store.budgetRemaining {
            let pct = store.total / (store.total + remaining) * 100
            budgetInfo = "Budget used: \(Int(pct))% | Remaining: $\(String(format: "%.2f", remaining))"
        } else {
            budgetInfo = "No budget set"
        }
        
        let lastExpense = store.expenses.first.map {
            "Last expense: $\(String(format: "%.2f", $0.amount)) on \($0.category.rawValue)"
        } ?? ""
        
        return """
        Trigger: \(trigger)
        \(budgetInfo)
        Total spent: $\(String(format: "%.2f", store.total))
        Week 1: $\(String(format: "%.2f", store.week1Total)) | Week 2: $\(String(format: "%.2f", store.week2Total))
        Days into period: \(store.daysSincePeriodStart())
        Predicted total: $\(String(format: "%.2f", store.spendingPrediction))
        Categories: \(categoryBreakdown)
        \(lastExpense)
        
        Should I send a notification?
        """
    }
    
    @MainActor
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
