//
//  Income.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-18.
//
import Foundation

enum IncomeSource: String, CaseIterable, Codable {
    case salary = "Salary"
    case freelance = "Freelance"
    case family = "Family"
    case government = "Government"
    case investment = "Investment"
    case other = "Other"
    
    var emoji: String {
        switch self {
        case .salary: return "💼"
        case .freelance: return "💻"
        case .family: return "👨‍👩‍👧"
        case .government: return "🏛️"
        case .investment: return "📈"
        case .other: return "💰"
        }
    }
}

struct Income: Identifiable, Codable {
    var id: UUID = UUID()
    var amount: Double
    var source: IncomeSource
    var note: String = ""
    var date: Date
}
