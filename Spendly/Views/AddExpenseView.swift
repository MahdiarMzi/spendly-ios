import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var amountText: String = ""
    @State private var selectedCategory: Category = .food
    @State private var selectedSubcategory: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var showSuccess: Bool = false
    @State private var showScanner = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Text("Add Expense")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Spacer()
                        Text("💸")
                            .font(.system(size: 32))
                    }
                    .padding(.top, 16)

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
                                    selectedSubcategory = ""
                                }
                            }
                        }
                    }

                    if !Subcategories.options(for: selectedCategory).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SUBCATEGORY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "555555"))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Subcategories.options(for: selectedCategory), id: \.self) { sub in
                                        Button {
                                            selectedSubcategory = selectedSubcategory == sub ? "" : sub
                                        } label: {
                                            Text(sub)
                                                .font(.system(size: 13, weight: selectedSubcategory == sub ? .bold : .regular))
                                                .foregroundColor(selectedSubcategory == sub ? Color(hex: "0D0D0D") : Color(hex: "666666"))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(selectedSubcategory == sub ? Color(hex: selectedCategory.color) : Color(hex: "1A1A1A"))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        TextField("e.g. lunch with friends", text: $note)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                    }

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
                        addExpense()
                    } label: {
                        Text(showSuccess ? "✓ Added!" : "Add Expense")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(showSuccess ? Color(hex: "55EFC4") : Color(hex: "FFE66D"))
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)

                    Button {
                        showScanner = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Import from Photo")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "FFE66D"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(14)
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showScanner) {
            SmartScannerView()
                .environmentObject(store)
        }
    }

    func addExpense() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            note: note,
            date: date
        )
        store.addExpense(expense)
        HapticManager.shared.success()
        amountText = ""
        note = ""
        date = Date()
        selectedCategory = .food
        selectedSubcategory = ""
        withAnimation {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccess = false }
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.system(size: 16))
                Text(category.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color(hex: category.color) : Color(hex: "888888"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color(hex: category.color) : Color(hex: "2A2A2A"),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
}
