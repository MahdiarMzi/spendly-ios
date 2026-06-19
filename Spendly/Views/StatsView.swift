import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var healthScore: Int = 0
    @State private var healthMessage: String = ""
    @State private var healthTip: String = ""
    @State private var isLoadingScore: Bool = false

    var scoreColor: Color {
        if healthScore >= 75 { return Color(hex: "55EFC4") }
        if healthScore >= 50 { return Color(hex: "FFE66D") }
        return Color(hex: "FF6B6B")
    }

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stats")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.white)
                            Text("May 16 – 30")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        Spacer()
                    }
                    .padding(.top, 16)

                    // Health Score Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("FINANCIAL HEALTH")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "555555"))
                            Spacer()
                            if isLoadingScore {
                                ProgressView()
                                    .tint(Color(hex: "FFE66D"))
                                    .scaleEffect(0.8)
                            }
                        }

                        if healthScore > 0 {
                            HStack(alignment: .center, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(hex: "252525"), lineWidth: 6)
                                        .frame(width: 70, height: 70)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(healthScore) / 100)
                                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                        .frame(width: 70, height: 70)
                                        .rotationEffect(.degrees(-90))
                                    Text("\(healthScore)")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(scoreColor)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(healthMessage)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "CCCCCC"))
                                    Text("💡 \(healthTip)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "666666"))
                                }
                            }
                        } else if !isLoadingScore {
                            Text("Add some expenses to see your health score")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "555555"))
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(16)

                    // Week comparison
                    HStack(spacing: 12) {
                        WeekCard(title: "Week 1", amount: store.week1Total, color: "FFE66D")
                        WeekCard(title: "Week 2", amount: store.week2Total, color: "FF6B6B")
                    }

                    // Budget card
                    if store.totalIncome > 0 {
                        BudgetCard(spent: store.total, remaining: store.incomeRemaining)
                    } else if let remaining = store.budgetRemaining {
                        BudgetCard(spent: store.total, remaining: remaining)
                    }

                    // Prediction card
                    if store.total > 0 {
                        PredictionCard(prediction: store.spendingPrediction, soFar: store.total)
                    }

                    // Top category
                    if let top = store.topCategory, store.total(for: top) > 0 {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: top.color).opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Text(top.emoji)
                                    .font(.system(size: 26))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Top Category")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "666666"))
                                Text(top.rawValue)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(hex: top.color))
                                Text("$\(store.total(for: top), specifier: "%.2f")")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "888888"))
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(16)
                    }

                    // Category breakdown
                    VStack(alignment: .leading, spacing: 14) {
                        Text("BY CATEGORY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "555555"))

                        ForEach(Category.allCases.filter { store.total(for: $0) > 0 }
                            .sorted { store.total(for: $0) > store.total(for: $1) }, id: \.self) { cat in
                            CategoryBar(
                                category: cat,
                                amount: store.total(for: cat),
                                total: store.total
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(16)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            loadHealthScore()
        }
    }

    func loadHealthScore() {
        guard !store.expenses.isEmpty else { return }
        isLoadingScore = true
        Task {
            let result = await HealthScoreService.shared.calculateScore(store: store)
            await MainActor.run {
                healthScore = result.score
                healthMessage = result.message
                healthTip = result.tip
                isLoadingScore = false
            }
        }
    }
}

struct WeekCard: View {
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
                .foregroundColor(.white)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: color))
                    .frame(width: geo.size.width, height: 3)
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(14)
    }
}

struct BudgetCard: View {
    let spent: Double
    let remaining: Double

    var total: Double { spent + max(remaining, 0) }
    var pct: Double { total > 0 ? min(spent / total, 1.0) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BUDGET")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "555555"))
                Spacer()
                Text(remaining >= 0 ? "$\(remaining, specifier: "%.2f") left" : "Over by $\(abs(remaining), specifier: "%.2f")")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(remaining >= 0 ? Color(hex: "55EFC4") : Color(hex: "FF6B6B"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "252525"))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(remaining >= 0 ? Color(hex: "55EFC4") : Color(hex: "FF6B6B"))
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
            HStack {
                Text("Spent: $\(spent, specifier: "%.2f")")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
                Spacer()
                Text("Income: $\(total, specifier: "%.2f")")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
            }
        }
        .padding(16)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }
}

struct PredictionCard: View {
    let prediction: Double
    let soFar: Double

    var body: some View {
        HStack(spacing: 12) {
            Text("📈")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("Spending Prediction")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "666666"))
                Text("$\(prediction, specifier: "%.2f") by end of period")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("Based on $\(soFar, specifier: "%.2f") spent so far")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }
}

struct CategoryBar: View {
    let category: Category
    let amount: Double
    let total: Double

    var pct: Double { total > 0 ? amount / total : 0 }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(category.emoji) \(category.rawValue)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "BBBBBB"))
                Spacer()
                Text("$\(amount, specifier: "%.2f")")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: category.color))
                Text("  \(Int(pct * 100))%")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "555555"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "252525"))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: category.color))
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 6)
        }
    }
}
