//
//  SettingsView.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-18.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showResetAlert = false
    @State private var showIncomeEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Spacer()
                        Text("⚙️")
                            .font(.system(size: 32))
                    }
                    .padding(.top, 16)

                    // Income Section
                    SettingsSection(title: "INCOME") {
                        SettingsRow(
                            icon: "dollarsign.circle.fill",
                            iconColor: "FFE66D",
                            title: "Edit Income",
                            subtitle: currentIncomeText
                        ) {
                            showIncomeEdit = true
                        }
                    }

                    // Notifications Section
                    SettingsSection(title: "NOTIFICATIONS") {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: "FF6B6B",
                            title: "Allow Notifications",
                            subtitle: "Budget alerts & weekly insights"
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }

                    // Data Section
                    SettingsSection(title: "DATA") {
                        SettingsRow(
                            icon: "arrow.clockwise.circle.fill",
                            iconColor: "4ECDC4",
                            title: "Reset Period",
                            subtitle: "Start a new 2-week period"
                        ) {
                            showResetAlert = true
                        }

                        Divider()
                            .background(Color(hex: "2A2A2A"))

                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: "FF6B6B",
                            title: "Delete All Data",
                            subtitle: "This cannot be undone"
                        ) {
                            showDeleteAlert = true
                        }
                    }

                    // App Info Section
                    SettingsSection(title: "APP") {
                        HStack {
                            Text("Version")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "888888"))
                            Spacer()
                            Text("1.0.0")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "555555"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    Text("Made with ❤️ by Mahdiar")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "333333"))
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showIncomeEdit) {
            EditIncomeView()
                .environmentObject(store)
        }
        .alert("Reset Period?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                store.resetPeriod()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all expenses for the current period. Recurring expenses will remain.")
        }
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Delete Everything", role: .destructive) {
                store.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete everything including your profile. You'll need to set up again.")
        }
    }

    var currentIncomeText: String {
        guard let profile = store.userProfile else { return "Not set" }
        let amt = profile.incomeType == .fixed ? profile.fixedIncome : profile.currentPeriodIncome
        return "$\(String(format: "%.2f", amt ?? 0)) (\(profile.incomeType.rawValue))"
    }
}

struct SettingsSection<Content: View>: View {
    
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "555555"))
            VStack(spacing: 0) {
                content
            }
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(14)
        }
    }
    
}

struct SettingsRow: View {
    let icon: String
    let iconColor: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: iconColor).opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: iconColor))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "666666"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "444444"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

struct EditIncomeView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @State private var incomeType: IncomeType = .fixed
    @State private var amountText: String = ""

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Edit Income")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "444444"))
                    }
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("INCOME TYPE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "555555"))
                    Picker("Income Type", selection: $incomeType) {
                        Text("Fixed").tag(IncomeType.fixed)
                        Text("Variable").tag(IncomeType.variable)
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("AMOUNT (CAD)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "555555"))
                    HStack {
                        Text("$")
                            .foregroundColor(Color(hex: "666666"))
                            .font(Font.system(size: 24, weight: Font.Weight.semibold))
                        TextField("0.00", text: $amountText)
                            .font(Font.system(size: 32, weight: Font.Weight.bold))
                            .foregroundColor(Color(hex: "FFE66D"))
                    }
                    .padding()
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(14)
                }

                Spacer()

                Button {
                    saveIncome()
                } label: {
                    Text("Save")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(hex: "0D0D0D"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "FFE66D"))
                        .cornerRadius(16)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            if let profile = store.userProfile {
                incomeType = profile.incomeType
                let amt = profile.incomeType == .fixed ? profile.fixedIncome : profile.currentPeriodIncome
                amountText = String(format: "%.2f", amt ?? 0)
            }
        }
    }

    func saveIncome() {
        guard let amount = Double(amountText), amount > 0 else { return }
        var profile = store.userProfile ?? UserProfile(incomeType: incomeType)
        profile.incomeType = incomeType
        if incomeType == .fixed {
            profile.fixedIncome = amount
        } else {
            profile.currentPeriodIncome = amount
        }
        profile.onboardingComplete = true
        store.saveProfile(profile)
        dismiss()
    }
}
