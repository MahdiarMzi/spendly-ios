import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var name: String = ""
    @State private var incomeType: IncomeType = .fixed
    @State private var incomeAmount: String = ""
    @State private var step: Int = 1

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("💸")
                    .font(.system(size: 64))

                if step == 1 {
                    VStack(spacing: 16) {
                        Text("Welcome to Spendly")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)

                        Text("What's your name?")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "666666"))

                        TextField("Your name...", text: $name)
                            .font(Font.system(size: 24, weight: Font.Weight.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                    }

                } else if step == 2 {
                    VStack(spacing: 16) {
                        Text("Hey \(name)! 👋")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)

                        Text("Is your income fixed or variable?")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "666666"))
                            .multilineTextAlignment(.center)

                        VStack(spacing: 12) {
                            IncomeTypeButton(
                                title: "Fixed",
                                subtitle: "Same amount every month",
                                emoji: "📅",
                                isSelected: incomeType == .fixed
                            ) { incomeType = .fixed }

                            IncomeTypeButton(
                                title: "Variable",
                                subtitle: "Changes each period",
                                emoji: "📊",
                                isSelected: incomeType == .variable
                            ) { incomeType = .variable }
                        }
                        .padding(.top, 8)
                    }

                } else {
                    VStack(spacing: 16) {
                        Text("What's your income\nthis period?")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("This helps us track your budget")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "666666"))

                        HStack {
                            Text("CAD $")
                                .foregroundColor(Color(hex: "666666"))
                                .font(Font.system(size: 18, weight: Font.Weight.semibold))
                            TextField("0.00", text: $incomeAmount)
                                .font(Font.system(size: 32, weight: Font.Weight.bold))
                                .foregroundColor(Color(hex: "FFE66D"))
                        }
                        .padding()
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(16)
                    }
                }

                Spacer()

                Button {
                    handleNext()
                } label: {
                    Text(step == 3 ? "Let's go!" : "Continue →")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(hex: "0D0D0D"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(step == 1 && name.isEmpty ? Color(hex: "333333") : Color(hex: "FFE66D"))
                        .cornerRadius(16)
                }
                .disabled(step == 1 && name.isEmpty)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }

    func handleNext() {
        if step == 1 {
            step = 2
        } else if step == 2 {
            step = 3
        } else {
            let amount = Double(incomeAmount) ?? 0
            var profile = UserProfile(incomeType: incomeType)
            profile.name = name
            if incomeType == .fixed {
                profile.fixedIncome = amount
            } else {
                profile.currentPeriodIncome = amount
            }
            profile.onboardingComplete = true
            store.saveProfile(profile)
        }
    }
}

struct IncomeTypeButton: View {
    let title: String
    let subtitle: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? Color(hex: "FFE66D") : .white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "666666"))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "FFE66D"))
                        .font(.system(size: 20))
                }
            }
            .padding(16)
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color(hex: "FFE66D") : Color(hex: "2A2A2A"),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
}
