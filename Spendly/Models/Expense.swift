//
//  Expense.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//
import Foundation

enum Category: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case health = "Health & Fitness"
    case education = "Education"
    case bills = "Bills & Subscriptions"
    case other = "Other"
    
    var emoji: String {
        switch self {
        case .food: return "🍔"
        case .transport: return "🚇"
        case .shopping: return "🛍️"
        case .entertainment: return "🎮"
        case .health: return "💪"
        case .education: return "📚"
        case .bills: return "📱"
        case .other: return "📦"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "FF6B6B"
        case .transport: return "4ECDC4"
        case .shopping: return "FFE66D"
        case .entertainment: return "A29BFE"
        case .health: return "55EFC4"
        case .education: return "74B9FF"
        case .bills: return "FD79A8"
        case .other: return "B2BEC3"
        }
    }
}

struct Expense: Identifiable, Codable {
    var id: UUID = UUID()
    var amount: Double
    var category: Category
    var subcategory: String = ""
    var note: String
    var date: Date
}

struct Subcategories {
    static let all: [Category: [String]] = [
        .food: ["Dining Out", "Groceries", "Coffee", "Alcohol", "Weed", "Fast Food", "Delivery"],
        .transport: ["Uber/Lyft", "Gas", "Transit", "Parking", "Car Wash"],
        .shopping: ["Clothes", "Electronics", "Amazon", "Personal Care", "Home"],
        .health: ["Gym", "Doctor", "Pharmacy", "Supplements", "Dental"],
        .entertainment: ["Movies", "Games", "Concerts", "Bars/Clubs", "Streaming"],
        .bills: ["Phone", "Internet", "Netflix", "Spotify", "Insurance", "Rent"],
        .education: ["Tuition", "Books", "Courses", "Supplies"],
        .other: ["Gift", "Travel", "Charity", "Misc"]
    ]
    
    static func options(for category: Category) -> [String] {
        return all[category] ?? []
    }
}
