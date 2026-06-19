//
//  IncomeView.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-18.
//
import SwiftUI

struct IncomeView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showAddIncome = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("\(store.incomes.count) sources")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    Spacer()
                    Button {
                        showAddIncome = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "55EFC4"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Summary cards
                HStack(spacing: 12) {
                    IncomeStatCard(title: "Total Income", amount: store.totalIncome, color: "55EFC4")
                    IncomeStatCard(title: "Remaining", amount: store.incomeRemaining, color: store.incomeRemaining >= 0 ? "55EFC4" : "FF6B6B")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                if store.incomes.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("💰")
                            .font(.system(size: 48))
                        Text("No income recorded yet")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "444444"))
                        Text("Tap + to add your income")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "333333"))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(store.incomes) { income in
                                IncomeRow(income: income) {
                                    store.deleteIncome(id: income.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView()
                .environmentObject(store)
        }
    }
}

struct IncomeStatCard: View {
    let title: String
    let amount: Double
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "666666"))
            Text("$\(amount, specifier: "%.2f")")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: color))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(14)
    }
}

struct IncomeRow: View {
    let income: Income
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "55EFC4").opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(income.source.emoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(income.note.isEmpty ? income.source.rawValue : income.note)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(income.source.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "55EFC4"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "55EFC4").opacity(0.15))
                        .cornerRadius(4)
                    Text(income.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "555555"))
                }
            }

            Spacer()

            Text("+$\(income.amount, specifier: "%.2f")")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "55EFC4"))

            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "555555"))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(14)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(14)
    }
}

struct AddIncomeView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss

    @State private var amountText: String = ""
    @State private var selectedSource: IncomeSource = .salary
    @State private var note: String = ""
    @State private var date: Date = Date()

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Text("Add Income")
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

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        HStack {
                            Text("CAD $")
                                .foregroundColor(Color(hex: "666666"))
                                .font(Font.system(size: 18, weight: Font.Weight.semibold))
                            TextField("0.00", text: $amountText)
                                .font(Font.system(size: 32, weight: Font.Weight.bold))
                                .foregroundColor(Color(hex: "55EFC4"))
                        }
                        .padding()
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(14)
                    }

                    // Source
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SOURCE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(IncomeSource.allCases, id: \.self) { source in
                                Button {
                                    selectedSource = source
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(source.emoji)
                                            .font(.system(size: 16))
                                        Text(source.rawValue)
                                            .font(.system(size: 12, weight: selectedSource == source ? .bold : .regular))
                                            .foregroundColor(selectedSource == source ? Color(hex: "55EFC4") : Color(hex: "888888"))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "1A1A1A"))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedSource == source ? Color(hex: "55EFC4") : Color(hex: "2A2A2A"),
                                                lineWidth: selectedSource == source ? 2 : 1
                                            )
                                    )
                                }
                            }
                        }
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        TextField("e.g. November paycheck", text: $note)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DATE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .padding()
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                    }

                    Button {
                        saveIncome()
                    } label: {
                        Text("Add Income")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "55EFC4"))
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    func saveIncome() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let income = Income(
            amount: amount,
            source: selectedSource,
            note: note,
            date: date
        )
        store.addIncome(income)
        HapticManager.shared.success()
        dismiss()
    }
}
