//
//  HealthScoreService.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-18.
//
import Foundation

class HealthScoreService {
    static let shared = HealthScoreService()
    private let ai = AIService()
    private let lastScoreKey = "last_health_score"
    private let lastScoreDateKey = "last_health_score_date"
    
    func calculateScore(store: ExpenseStore) async -> (score: Int, message: String, tip: String) {
        // Check if we calculated score in last 24 hours
        let lastDate = UserDefaults.standard.double(forKey: lastScoreDateKey)
        let now = Date().timeIntervalSince1970
        
        if now - lastDate < 86400 {
            // Return cached score
            let cachedScore = UserDefaults.standard.integer(forKey: lastScoreKey)
            if cachedScore > 0 {
                return (cachedScore, "Based on your recent activity", "Keep it up!")
            }
        }
        
        let prompt = buildPrompt(store: store)
        
        do {
            let response = try await ai.sendMessage(
                messages: [["role": "user", "content": prompt]],
                system: buildSystem()
            )
            
            let cleaned = response
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let data = cleaned.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let score = json["score"] as? Int,
               let message = json["message"] as? String,
               let tip = json["tip"] as? String {
                
                UserDefaults.standard.set(score, forKey: lastScoreKey)
                UserDefaults.standard.set(now, forKey: lastScoreDateKey)
                
                return (score, message, tip)
            }
        } catch {
            print("Health score error: \(error)")
        }
        
        return (0, "Could not calculate score", "Try again later")
    }
    
    private func buildSystem() -> String {
        return """
        You are a financial health analyzer. Analyze spending data and return a health score.
        Respond ONLY with JSON in this exact format, no markdown:
        {"score": 75, "message": "2-3 sentence analysis of their financial health", "tip": "One specific actionable tip"}
        
        Score from 0-100 based on:
        - Staying under budget (0-30 points)
        - Balanced spending across categories (0-20 points)
        - Week over week improvement (0-20 points)
        - Having income recorded (0-15 points)
        - Reasonable daily average (0-15 points)
        
        Be encouraging but honest. No markdown formatting.
        """
    }
    
    private func buildPrompt(store: ExpenseStore) -> String {
        let categoryBreakdown = Category.allCases
            .filter { store.total(for: $0) > 0 }
            .map { "\($0.rawValue): $\(String(format: "%.2f", store.total(for: $0)))" }
            .joined(separator: ", ")
        
        let budgetInfo: String
        if store.totalIncome > 0 {
            let pct = store.totalIncome > 0 ? (store.total / store.totalIncome * 100) : 0
            budgetInfo = "Income: $\(String(format: "%.2f", store.totalIncome)) | Spent: \(Int(pct))% of income"
        } else if let remaining = store.budgetRemaining {
            budgetInfo = "Budget remaining: $\(String(format: "%.2f", remaining))"
        } else {
            budgetInfo = "No budget set"
        }
        
        return """
        Calculate financial health score:
        \(budgetInfo)
        Total spent: $\(String(format: "%.2f", store.total))
        Week 1: $\(String(format: "%.2f", store.week1Total)) | Week 2: $\(String(format: "%.2f", store.week2Total))
        Days into period: \(store.daysSincePeriodStart())
        Categories: \(categoryBreakdown.isEmpty ? "No expenses" : categoryBreakdown)
        Daily average: $\(String(format: "%.2f", store.total / Double(max(store.daysSincePeriodStart(), 1))))
        """
    }
}
