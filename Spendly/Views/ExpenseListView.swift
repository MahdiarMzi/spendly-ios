import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedCategory: Category? = nil
    @State private var expenseToEdit: Expense? = nil
    @State private var searchText: String = ""
    @State private var showFilters = false
    @State private var minAmount: Double = 0
    @State private var maxAmount: Double = 10000
    @State private var dateFilter: DateFilter = .all

    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }

    var filteredExpenses: [Expense] {
        var result = store.expenses

        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.note.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                String(format: "%.2f", $0.amount).contains(searchText)
            }
        }

        if minAmount > 0 {
            result = result.filter { $0.amount >= minAmount }
        }
        if maxAmount < 10000 {
            result = result.filter { $0.amount <= maxAmount }
        }

        let calendar = Calendar.current
        switch dateFilter {
        case .thisWeek:
            result = result.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            result = result.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .all:
            break
        }

        return result
    }

    var isFiltered: Bool {
        minAmount > 0 || maxAmount < 10000 || dateFilter != .all
    }

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("\(filteredExpenses.count) transactions")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Total")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "666666"))
                        Text("$\(store.total, specifier: "%.2f")")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "FFE66D"))
                    }
                    Button {
                        showFilters = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(isFiltered ? Color(hex: "FFE66D") : Color(hex: "444444"))
                            if isFiltered {
                                Circle()
                                    .fill(Color(hex: "FF6B6B"))
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "666666"))
                    TextField("Search expenses...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "555555"))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "1A1A1A"))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(Category.allCases.filter { store.total(for: $0) > 0 }, id: \.self) { cat in
                            FilterChip(
                                title: "\(cat.emoji) \(cat.rawValue)",
                                isSelected: selectedCategory == cat
                            ) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                if filteredExpenses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(searchText.isEmpty && !isFiltered ? "📭" : "🔍")
                            .font(.system(size: 48))
                        Text(searchText.isEmpty && !isFiltered ? "No expenses yet" : "No results found")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "444444"))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExpenses) { expense in
                                ExpenseRow(
                                    expense: expense,
                                    onEdit: { expenseToEdit = expense },
                                    onDelete: {
                                        HapticManager.shared.medium()
                                        store.deleteExpense(id: expense.id)
                                    }                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(item: $expenseToEdit) { expense in
            EditExpenseView(expense: expense)
                .environmentObject(store)
        }
        .sheet(isPresented: $showFilters) {
            FilterView(minAmount: $minAmount, maxAmount: $maxAmount, dateFilter: $dateFilter)
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var minAmount: Double
    @Binding var maxAmount: Double
    @Binding var dateFilter: ExpenseListView.DateFilter

    @State private var minText: String = ""
    @State private var maxText: String = ""

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Filters")
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
                    Text("DATE RANGE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "555555"))
                    HStack(spacing: 8) {
                        ForEach(ExpenseListView.DateFilter.allCases, id: \.self) { filter in
                            Button {
                                dateFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 12, weight: dateFilter == filter ? .bold : .regular))
                                    .foregroundColor(dateFilter == filter ? Color(hex: "0D0D0D") : Color(hex: "666666"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(dateFilter == filter ? Color(hex: "FFE66D") : Color(hex: "1A1A1A"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("AMOUNT RANGE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "555555"))
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Min $")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "666666"))
                            TextField("0", text: $minText)
                                .font(Font.system(size: 20, weight: Font.Weight.bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "1A1A1A"))
                                .cornerRadius(12)
                                .onChange(of: minText) {
                                    minAmount = Double(minText) ?? 0
                                }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Max $")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "666666"))
                            TextField("10000", text: $maxText)
                                .font(Font.system(size: 20, weight: Font.Weight.bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "1A1A1A"))
                                .cornerRadius(12)
                                .onChange(of: maxText) {
                                    maxAmount = Double(maxText) ?? 10000
                                }
                        }
                    }
                }

                Spacer()

                Button {
                    minAmount = 0
                    maxAmount = 10000
                    dateFilter = .all
                    minText = ""
                    maxText = ""
                } label: {
                    Text("Reset Filters")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "666666"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(14)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Apply")
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
            minText = minAmount > 0 ? String(format: "%.0f", minAmount) : ""
            maxText = maxAmount < 10000 ? String(format: "%.0f", maxAmount) : ""
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: expense.category.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(expense.category.emoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.note.isEmpty ? expense.category.rawValue : expense.note)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    if !expense.subcategory.isEmpty {
                        Text(expense.subcategory)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: expense.category.color))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: expense.category.color).opacity(0.15))
                            .cornerRadius(4)
                    }
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "555555"))
                }
            }

            Spacer()

            Text("$\(expense.amount, specifier: "%.2f")")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: expense.category.color))

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color(hex: "0D0D0D") : Color(hex: "666666"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "FFE66D") : Color(hex: "1A1A1A"))
                .cornerRadius(20)
        }
    }
}
