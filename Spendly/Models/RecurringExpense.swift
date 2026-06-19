//
//  RecurringExpense.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//

import Foundation

enum RecurringFrequency: String, CaseIterable, Codable {
    case monthly = "Monthly"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
}

struct RecurringExpense: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var category: Category
    var frequency: RecurringFrequency
    var dayOfMonth: Int?
    var dayOfWeek: Int?
    var isActive: Bool = true
    var lastTriggered: Date?
}
