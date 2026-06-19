//
//  EditExpenseView.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//
import SwiftUI

struct EditExpenseView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    
    let expense: Expense
    
    @State private var amountText: String
    @State private var selectedCategory: Category
    @State private var note: String
    @State private var date: Date
    
    init(expense: Expense) {
        self.expense = expense
        _amountText = State(initialValue: String(format: "%.2f", expense.amount))
        _selectedCategory = State(initialValue: expense.category)
        _note = State(initialValue: expense.note)
        _date = State(initialValue: expense.date)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    HStack {
                        Text("Edit Expense")
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
                                .foregroundColor(Color(hex: "FFE66D"))
                        }
                        .padding()
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(14)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Category.allCases, id: \.self) { cat in
                                CategoryButton(
                                    category: cat,
                                    isSelected: selectedCategory == cat
                                ) {
                                    selectedCategory = cat
                                }
                            }
                        }
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        TextField("e.g. lunch with friends", text: $note)
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
                    
                    // Save Button
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save Changes")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "FFE66D"))
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    func saveChanges() {
        guard let amount = Double(amountText), amount > 0 else { return }
        store.deleteExpense(id: expense.id)
        let updated = Expense(
            amount: amount,
            category: selectedCategory,
            note: note,
            date: date
        )
        store.addExpense(updated)
        dismiss()
    }
}
