import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ChatIntent: Codable {
    let action: String
    let expenseId: String?
    let amount: Double?
    let category: String?
    let note: String?
    let newAmount: Double?
    let newNote: String?
    let newCategory: String?
    let incomeAmount: Double?
}

struct ChatView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    private let ai = AIService()

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Assistant")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("Powered by GPT-4o")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    Spacer()
                    Text("🤖")
                        .font(.system(size: 32))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }

                HStack(spacing: 12) {
                    TextField("Ask anything or log an expense...", text: $inputText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(24)

                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(inputText.isEmpty ? Color(hex: "333333") : Color(hex: "FFE66D"))
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "111111"))
            }
        }
        .onAppear { loadInitialContext() }
    }

    func loadInitialContext() {
        guard messages.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let response = try await ai.sendMessage(
                    messages: [["role": "user", "content": "greet"]],
                    system: buildConversationSystemPrompt()
                )
                await MainActor.run {
                    messages.append(ChatMessage(content: response, isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(content: "Hey! I'm your Spendly assistant. Ask me anything about your spending, or just tell me what you bought.", isUser: false))
                    isLoading = false
                }
            }
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(content: text, isUser: true))
        inputText = ""
        isLoading = true

        Task {
            let intent = await detectIntent(userText: text)
            let actionResult = await executeIntent(intent)

            do {
                var conversationMessages = buildConversationHistory(userText: text)

                if let result = actionResult {
                    conversationMessages.append([
                        "role": "system",
                        "content": "Action just performed: \(result). Acknowledge this briefly and naturally in your reply."
                    ])
                }

                let response = try await ai.sendMessage(
                    messages: conversationMessages,
                    system: buildConversationSystemPrompt()
                )

                await MainActor.run {
                    messages.append(ChatMessage(content: response, isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(content: "Connection error. Please try again.", isUser: false))
                    isLoading = false
                }
            }
        }
    }

    func detectIntent(userText: String) async -> ChatIntent? {
        let expenseList = store.expenses.prefix(40).map {
            "ID:\($0.id.uuidString.prefix(8)) | $\(String(format: "%.2f", $0.amount)) | \($0.category.rawValue) | \($0.note) | \($0.date.formatted(date: .abbreviated, time: .omitted))"
        }.joined(separator: "\n")

        let systemPrompt = """
        You are an intent classifier for an expense tracking app. Analyze the user message and return ONLY valid JSON with no extra text, no markdown, no explanation.

        The user's existing expenses (for matching delete/edit requests):
        \(expenseList.isEmpty ? "No expenses yet." : expenseList)

        Return exactly this JSON structure:
        {
          "action": "add" | "delete" | "edit" | "answer" | "update_income",
          "expenseId": "first 8 chars of expense ID" or null,
          "amount": number or null,
          "category": "food" | "transport" | "shopping" | "entertainment" | "health" | "education" | "bills" | "other" or null,
          "note": "clean merchant/item name" or null,
          "newAmount": number or null,
          "newNote": "new description" or null,
          "newCategory": category string or null,
          "incomeAmount": number or null
        }

        Classification rules:
        - "add": user is logging a new purchase or expense they made
        - "delete": user wants to remove an existing expense — match the best ID from the list above using amount, merchant, category, or date
        - "edit": user wants to change something about an existing expense — match the best ID
        - "update_income": user is stating their income amount for this period
        - "answer": user is asking a question, making a comment, or anything else that does not change data

        For "add": extract amount, category, and a clean short note (merchant name or item).
        For "delete": set expenseId to the best matching expense ID prefix. Set amount and note to what you matched.
        For "edit": set expenseId to the best match. Set newAmount and/or newNote and/or newCategory to what should change.
        For "update_income": set incomeAmount only if the amount is above 100.
        When unsure between "add" and "answer", choose "answer".
        """

        do {
            let raw = try await ai.sendMessage(
                messages: [["role": "user", "content": userText]],
                system: systemPrompt
            )
            let cleaned = raw
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let data = cleaned.data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(ChatIntent.self, from: data)
        } catch {
            print("Intent detection error:", error)
            return nil
        }
    }

    @MainActor
    func executeIntent(_ intent: ChatIntent?) async -> String? {
        guard let intent = intent else { return nil }

        switch intent.action {

        case "add":
            guard let amount = intent.amount, amount > 0 else { return nil }
            let category = Category.allCases.first { $0.rawValue == intent.category } ?? .other
            let note = intent.note ?? "Expense"
            let expense = Expense(amount: amount, category: category, note: note, date: Date())
            store.addExpense(expense)
            return "Added \(note) — $\(String(format: "%.2f", amount)) (\(category.rawValue))"

        case "delete":
            guard let idPrefix = intent.expenseId else { return nil }
            guard let expense = store.expenses.first(where: {
                $0.id.uuidString.prefix(8).lowercased() == idPrefix.lowercased()
            }) else {
                return "Could not find a matching expense to delete."
            }
            let description = "\(expense.note) — $\(String(format: "%.2f", expense.amount))"
            store.deleteExpense(id: expense.id)
            return "Deleted: \(description)"

        case "edit":
            guard let idPrefix = intent.expenseId else { return nil }
            guard let index = store.expenses.firstIndex(where: {
                $0.id.uuidString.prefix(8).lowercased() == idPrefix.lowercased()
            }) else {
                return "Could not find a matching expense to edit."
            }
            var updated = store.expenses[index]
            if let newAmount = intent.newAmount, newAmount > 0 { updated.amount = newAmount }
            if let newNote = intent.newNote, !newNote.isEmpty { updated.note = newNote }
            if let newCat = intent.newCategory,
               let cat = Category.allCases.first(where: { $0.rawValue == newCat }) {
                updated.category = cat
            }
            store.updateExpense(updated)
            return "Updated to \(updated.note) — $\(String(format: "%.2f", updated.amount)) (\(updated.category.rawValue))"

        case "update_income":
            guard let amount = intent.incomeAmount,
                  amount > 100,
                  let profile = store.userProfile,
                  profile.incomeType == .variable else { return nil }
            var updated = profile
            updated.currentPeriodIncome = amount
            store.saveProfile(updated)
            return "Income updated to $\(String(format: "%.2f", amount))"

        default:
            return nil
        }
    }

    func buildConversationSystemPrompt() -> String {
        let expenseList = store.expenses.prefix(50).map {
            "ID:\($0.id.uuidString.prefix(8)) | $\(String(format: "%.2f", $0.amount)) | \($0.category.rawValue) | \($0.note) | \($0.date.formatted(date: .abbreviated, time: .omitted))"
        }.joined(separator: "\n")

        let incomeStr: String
        if let profile = store.userProfile {
            let amt = profile.incomeType == .fixed ? profile.fixedIncome : profile.currentPeriodIncome
            incomeStr = "CAD $\(String(format: "%.2f", amt ?? 0)) (\(profile.incomeType.rawValue))"
        } else {
            incomeStr = "not set"
        }

        let categoryBreakdown = Category.allCases
            .filter { store.total(for: $0) > 0 }
            .sorted { store.total(for: $0) > store.total(for: $1) }
            .map { "\($0.rawValue): $\(String(format: "%.2f", store.total(for: $0)))" }
            .joined(separator: " | ")

        let budgetStr: String
        if let remaining = store.budgetRemaining {
            let daysLeft = max(14 - store.daysSincePeriodStart(), 0)
            let dailyLeft = remaining / Double(max(daysLeft, 1))
            budgetStr = "Remaining: $\(String(format: "%.2f", remaining)) | Days left: \(daysLeft) | Daily budget: $\(String(format: "%.2f", dailyLeft))"
        } else {
            budgetStr = "No budget set"
        }

        let avgDaily = store.total / Double(max(store.daysSincePeriodStart(), 1))

        return """
        You are Spendly's financial assistant — smart, warm, and direct.
        Currency: CAD. Never use markdown. Plain text only. Keep replies to 2-4 sentences unless the user asks for more detail.

        USER FINANCIAL DATA:
        Income this period: \(incomeStr)
        Total spent: $\(String(format: "%.2f", store.total))
        Week 1: $\(String(format: "%.2f", store.week1Total)) | Week 2: $\(String(format: "%.2f", store.week2Total))
        Average daily spend: $\(String(format: "%.2f", avgDaily))
        Predicted end-of-period total: $\(String(format: "%.2f", store.spendingPrediction))
        Budget: \(budgetStr)
        By category: \(categoryBreakdown.isEmpty ? "no expenses yet" : categoryBreakdown)

        ALL EXPENSES:
        \(expenseList.isEmpty ? "No expenses yet." : expenseList)

        BEHAVIOR:
        - Never ask for income — it is already set.
        - Never invent numbers. Only use the data above.
        - If the user added, deleted, or edited an expense, acknowledge it naturally in one sentence then move on.
        - If you notice overspending or a tight budget, mention it proactively but kindly.
        - For the greeting: give a warm welcome back with a 2-sentence smart summary of their current financial state.
        - If there are no expenses yet, welcome them and explain what they can do.
        - Always sound like a knowledgeable friend, not a robot.
        """
    }

    func buildConversationHistory(userText: String) -> [[String: String]] {
        var result: [[String: String]] = []
        for msg in messages.suffix(12) {
            result.append(["role": msg.isUser ? "user" : "assistant", "content": msg.content])
        }
        result.append(["role": "user", "content": userText])
        return result
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(message.isUser ? Color(hex: "0D0D0D") : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color(hex: "FFE66D") : Color(hex: "1A1A1A"))
                .cornerRadius(18)
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(hex: "555555"))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(12)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(18)
        .onAppear { animating = true }
    }
}
