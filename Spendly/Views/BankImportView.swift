//
//  BankImportView.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-18.
//

import SwiftUI

struct BankImportView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @State private var showGallery = false
    @State private var selectedImage: UIImage?
    @State private var isScanning = false
    @State private var transactions: [ImportedTransaction] = []
    @State private var showResults = false
    @State private var errorMessage: String?
    @State private var duplicateCount = 0

    private let gemini = GeminiService()

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    Text("Import from Bank")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "444444"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                if showResults {
                    resultsView
                } else if let image = selectedImage {
                    imagePreviewView(image: image)
                } else {
                    emptyStateView
                }
            }
        }
        .sheet(isPresented: $showGallery) {
            GalleryPicker(image: $selectedImage, onImageSelected: scanImage)
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("🏦")
                    .font(.system(size: 64))
                Text("Import Bank Transactions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Take a screenshot of your bank app's transaction list and import it here. Works with any bank!")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    BankTip(emoji: "1️⃣", text: "Open your bank app")
                    BankTip(emoji: "2️⃣", text: "Go to transactions")
                }
                HStack(spacing: 12) {
                    BankTip(emoji: "3️⃣", text: "Take a screenshot")
                    BankTip(emoji: "4️⃣", text: "Import here")
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button {
                showGallery = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "photo.fill")
                    Text("Choose Screenshot")
                }
                .font(.system(size: 17, weight: .black))
                .foregroundColor(Color(hex: "0D0D0D"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "FFE66D"))
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    func imagePreviewView(image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(16)
                .padding(.horizontal, 20)

            if isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color(hex: "FFE66D"))
                        .scaleEffect(1.5)
                    Text("AI is reading your transactions...")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "666666"))
                }
                .padding(.top, 20)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .padding(.horizontal, 20)
            }

            Spacer()

            if !isScanning {
                VStack(spacing: 10) {
                    Button {
                        scanImage()
                    } label: {
                        Text("Scan Transactions")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "FFE66D"))
                            .cornerRadius(16)
                    }

                    Button {
                        selectedImage = nil
                        errorMessage = nil
                    } label: {
                        Text("Choose Different Image")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "666666"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    var resultsView: some View {
        VStack(spacing: 0) {
            if duplicateCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color(hex: "FFE66D"))
                    Text("\(duplicateCount) duplicate transactions skipped")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "FFE66D"))
                }
                .padding(12)
                .background(Color(hex: "FFE66D").opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(transactions.indices, id: \.self) { i in
                        ImportedTransactionRow(
                            transaction: $transactions[i]
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }

            VStack(spacing: 10) {
                Text("\(transactions.filter { $0.selected }.count) of \(transactions.count) selected")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "666666"))

                Button {
                    importSelected()
                } label: {
                    Text("Import Selected")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(hex: "0D0D0D"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "FFE66D"))
                        .cornerRadius(16)
                }

                Button {
                    showResults = false
                    selectedImage = nil
                    transactions = []
                } label: {
                    Text("Start Over")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "555555"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "111111"))
        }
    }

    func scanImage() {
        guard let image = selectedImage else { return }
        isScanning = true
        errorMessage = nil

        Task {
            do {
                let result = try await gemini.scanBankStatement(image: image)
                let filtered = filterDuplicates(result)
                await MainActor.run {
                    transactions = filtered.unique
                    duplicateCount = filtered.duplicateCount
                    isScanning = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not read transactions. Try a clearer screenshot."
                    isScanning = false
                }
            }
        }
    }

    func filterDuplicates(_ imported: [ImportedTransaction]) -> (unique: [ImportedTransaction], duplicateCount: Int) {
        var unique: [ImportedTransaction] = []
        var dupCount = 0

        for transaction in imported {
            let isDuplicate = store.expenses.contains { expense in
                abs(expense.amount - transaction.amount) < 0.01 &&
                Calendar.current.isDate(expense.date, equalTo: transaction.date, toGranularity: .day)
            }
            if isDuplicate {
                dupCount += 1
            } else {
                unique.append(transaction)
            }
        }
        return (unique, dupCount)
    }

    func importSelected() {
        let selected = transactions.filter { $0.selected }
        for t in selected {
            let expense = Expense(
                amount: t.amount,
                category: t.category,
                subcategory: "",
                note: t.note,
                date: t.date
            )
            store.addExpense(expense)
        }
        HapticManager.shared.success()
        dismiss()
    }
}

struct ImportedTransaction: Identifiable {
    let id = UUID()
    var amount: Double
    var note: String
    var category: Category
    var date: Date
    var selected: Bool = true
}

struct ImportedTransactionRow: View {
    @Binding var transaction: ImportedTransaction

    var body: some View {
        HStack(spacing: 12) {
            Button {
                transaction.selected.toggle()
            } label: {
                Image(systemName: transaction.selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(transaction.selected ? Color(hex: "FFE66D") : Color(hex: "444444"))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: transaction.category.color).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(transaction.category.emoji)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "555555"))
            }

            Spacer()

            Text("$\(transaction.amount, specifier: "%.2f")")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: transaction.category.color))
        }
        .padding(12)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .opacity(transaction.selected ? 1.0 : 0.5)
    }
}

struct BankTip: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "888888"))
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(10)
    }
}

