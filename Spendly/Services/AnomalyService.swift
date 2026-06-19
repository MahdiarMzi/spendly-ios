//
//  AnomalyService.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-18.
//
import Foundation

class AnomalyService {
    static let shared = AnomalyService()
    private let ai = AIService()
    
    func checkForAnomaly(newExpense: Expense, store: ExpenseStore) async -> String? {
        guard store.expenses.count >= 3 else { return nil }
        
        let categoryExpenses = store.expenses
            .filter { $0.category == newExpense.category && $0.id != newExpense.id }
            .prefix(10)
            .map { $0.amount }
        
        guard !categoryExpenses.isEmpty else { return nil }
        
        let average = categoryExpenses.reduce(0, +) / Double(categoryExpenses.count)
        
        // Only check if new expense is 2x the average
        guard newExpense.amount > average * 2 else { return nil }
        
        let prompt = """
        New expense: $\(String(format: "%.2f", newExpense.amount)) on \(newExpense.category.rawValue)
        Average for this category: $\(String(format: "%.2f", average)) (based on \(categoryExpenses.count) past expenses)
        
        This is \(String(format: "%.1f", newExpense.amount / average))x the usual amount.
        Write a friendly 1-sentence observation about this unusual expense. No markdown. Be casual and brief.
        """
        
        do {
            let response = try await ai.sendMessage(
                messages: [["role": "user", "content": prompt]],
                system: "You are a friendly financial assistant. Write casual, brief observations. No markdown. Max 20 words."
            )
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
