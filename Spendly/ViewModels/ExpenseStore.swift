import Foundation
import Combine

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var userProfile: UserProfile?
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var incomes: [Income] = []
    private let incomesKey = "saved_incomes"
    
    private let expensesKey = "saved_expenses"
    private let profileKey = "user_profile"
    private let recurringKey = "saved_recurring"
    
    init() {
        loadExpenses()
        loadProfile()
        loadRecurring()
        loadIncomes()
    }
    
    // MARK: - Expenses
    func addExpense(_ expense: Expense) {
        expenses.insert(expense, at: 0)
        saveExpenses()
        AINotificationService.shared.checkAfterExpense(store: self)
        
        // Check for anomaly
        Task {
            if let anomaly = await AnomalyService.shared.checkForAnomaly(newExpense: expense, store: self) {
                await MainActor.run {
                    self.lastAnomalyMessage = anomaly
                }
            }
        }
    }

    @Published var lastAnomalyMessage: String? = nil
    
    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
        saveExpenses()
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses()
        }
    }
    
    // MARK: - Stats
    var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var week1Total: Double {
        expenses.filter { isWeek1($0.date) }.reduce(0) { $0 + $1.amount }
    }
    
    var week2Total: Double {
        expenses.filter { !isWeek1($0.date) }.reduce(0) { $0 + $1.amount }
    }
    
    func total(for category: Category) -> Double {
        expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
    }
    
    var topCategory: Category? {
        Category.allCases.max { total(for: $0) < total(for: $1) }
    }
    
    var spendingPrediction: Double {
        guard !expenses.isEmpty else { return 0 }
        let daysSoFar = daysSincePeriodStart()
        guard daysSoFar > 0 else { return total }
        return (total / Double(daysSoFar)) * 14
    }
    
    var budgetRemaining: Double? {
        guard let profile = userProfile else { return nil }
        let income = profile.incomeType == .fixed
            ? profile.fixedIncome
            : profile.currentPeriodIncome
        guard let income = income else { return nil }
        return income - total
    }
    
    // MARK: - Period
    private let periodStart: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: Date())
        return cal.date(from: comps) ?? Date()
    }()
    
    func isWeek1(_ date: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.day], from: periodStart, to: date).day ?? 0
        return diff < 7
    }
    
    func daysSincePeriodStart() -> Int {
        let diff = Calendar.current.dateComponents([.day], from: periodStart, to: Date()).day ?? 0
        return max(1, diff)
    }
    
    // MARK: - Recurring
    func addRecurring(_ expense: RecurringExpense) {
        recurringExpenses.append(expense)
        saveRecurring()
        NotificationManager.shared.scheduleRecurringNotification(for: expense)
    }
    
    func deleteRecurring(id: UUID) {
        recurringExpenses.removeAll { $0.id == id }
        saveRecurring()
        NotificationManager.shared.cancelNotification(for: id)
    }
    
    func confirmRecurring(_ recurring: RecurringExpense) {
        let expense = Expense(
            amount: recurring.amount,
            category: recurring.category,
            note: recurring.title,
            date: Date()
        )
        addExpense(expense)
        var updated = recurring
        updated.lastTriggered = Date()
        if let index = recurringExpenses.firstIndex(where: { $0.id == recurring.id }) {
            recurringExpenses[index] = updated
            saveRecurring()
        }
    }
    
    // MARK: - Persistence
    func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: expensesKey)
        }
    }
    
    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let saved = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = saved
        }
    }
    
    func saveProfile(_ profile: UserProfile) {
        userProfile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = saved
        }
    }
    
    private func saveRecurring() {
        if let data = try? JSONEncoder().encode(recurringExpenses) {
            UserDefaults.standard.set(data, forKey: recurringKey)
        }
    }
    
    func loadRecurring() {
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let saved = try? JSONDecoder().decode([RecurringExpense].self, from: data) {
            recurringExpenses = saved
        }
    }
    func deleteAllData() {
        expenses = []
        recurringExpenses = []
        userProfile = nil
        UserDefaults.standard.removeObject(forKey: expensesKey)
        UserDefaults.standard.removeObject(forKey: recurringKey)
        UserDefaults.standard.removeObject(forKey: profileKey)
    }

    func resetPeriod() {
        expenses = []
        saveExpenses()
    }
    
    // MARK: - Income
    func addIncome(_ income: Income) {
        incomes.insert(income, at: 0)
        saveIncomes()
    }

    func deleteIncome(id: UUID) {
        incomes.removeAll { $0.id == id }
        saveIncomes()
    }

    var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    var incomeRemaining: Double {
        totalIncome - total
    }

    private func saveIncomes() {
        if let data = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(data, forKey: incomesKey)
        }
    }

    func loadIncomes() {
        if let data = UserDefaults.standard.data(forKey: incomesKey),
           let saved = try? JSONDecoder().decode([Income].self, from: data) {
            incomes = saved
        }
    }
}
