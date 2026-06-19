//
//  UserProfile.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//
import Foundation

enum IncomeType: String, Codable {
    case fixed
    case variable
}

struct UserProfile: Codable {
    var name: String = ""
    var incomeType: IncomeType
    var fixedIncome: Double?
    var currentPeriodIncome: Double?
    var onboardingComplete: Bool = false
}
