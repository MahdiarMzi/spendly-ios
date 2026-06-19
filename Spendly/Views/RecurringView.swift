import SwiftUI

struct RecurringView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recurring")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("Automatic bills & payments")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    Spacer()
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "FFE66D"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                if store.recurringExpenses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🔄")
                            .font(.system(size: 48))
                        Text("No recurring expenses")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "444444"))
                        Text("Tap + to add bills that repeat")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "333333"))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.recurringExpenses) { recurring in
                                RecurringRow(recurring: recurring)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRecurringView()
                .environmentObject(store)
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}

struct RecurringRow: View {
    @EnvironmentObject var store: ExpenseStore
    let recurring: RecurringExpense
    @State private var showConfirm = false

    var scheduleText: String {
        switch recurring.frequency {
        case .monthly:
            return "Every month on day \(recurring.dayOfMonth ?? 1)"
        case .weekly:
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let day = days[(recurring.dayOfWeek ?? 2) - 1]
            return "Every \(day)"
        case .biweekly:
            return "Every 2 weeks on day \(recurring.dayOfMonth ?? 1)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: recurring.category.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(recurring.category.emoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(recurring.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(scheduleText)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "555555"))
                }

                Spacer()

                Text("$\(recurring.amount, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: recurring.category.color))

                Menu {
                    Button {
                        showConfirm = true
                    } label: {
                        Label("Mark as Paid", systemImage: "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        HapticManager.shared.medium()
                        store.deleteRecurring(id: recurring.id)
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
        .alert("Mark as Paid?", isPresented: $showConfirm) {
            Button("Yes, log it") {
                store.confirmRecurring(recurring)
                HapticManager.shared.success()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will add $\(String(format: "%.2f", recurring.amount)) for \(recurring.title) to your expenses.")
        }
    }
}

struct AddRecurringView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedCategory: Category = .bills
    @State private var frequency: RecurringFrequency = .monthly
    @State private var dayOfMonth: Int = 1
    @State private var dayOfWeek: Int = 2

    let days = Array(1...28)
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Text("Add Recurring")
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
                        Text("NAME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        TextField("e.g. Netflix, Rent, Gym", text: $title)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                    }

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
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FREQUENCY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))
                        Picker("Frequency", selection: $frequency) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .colorScheme(.dark)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(frequency == .weekly ? "DAY OF WEEK" : "DAY OF MONTH")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))

                        if frequency == .weekly {
                            Picker("Day of week", selection: $dayOfWeek) {
                                ForEach(1...7, id: \.self) { i in
                                    Text(weekdays[i - 1]).tag(i)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                            .colorScheme(.dark)
                        } else {
                            Picker("Day of month", selection: $dayOfMonth) {
                                ForEach(days, id: \.self) { d in
                                    Text("Day \(d)").tag(d)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                            .colorScheme(.dark)
                        }
                    }

                    Button {
                        saveRecurring()
                    } label: {
                        Text("Add Recurring Expense")
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

    func saveRecurring() {
        guard !title.isEmpty, let amount = Double(amountText), amount > 0 else { return }
        let recurring = RecurringExpense(
            title: title,
            amount: amount,
            category: selectedCategory,
            frequency: frequency,
            dayOfMonth: frequency != .weekly ? dayOfMonth : nil,
            dayOfWeek: frequency == .weekly ? dayOfWeek : nil
        )
        store.addRecurring(recurring)
        HapticManager.shared.success()
        dismiss()
    }
}
