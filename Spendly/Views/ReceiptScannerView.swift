import SwiftUI

struct SmartScannerView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @State private var scanMode: ScanMode? = nil
    @State private var showGallery = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var isScanning = false
    @State private var errorMessage: String?

    // Receipt mode
    @State private var scannedAmount: Double?
    @State private var scannedCategory: Category = .other
    @State private var scannedNote: String = ""
    @State private var showReceiptResult = false

    // Bank mode
    @State private var transactions: [ImportedTransaction] = []
    @State private var showBankResults = false
    @State private var duplicateCount = 0

    private let gemini = GeminiService()

    enum ScanMode {
        case receipt, bank
    }

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    if scanMode != nil {
                        Button {
                            resetAll()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "666666"))
                        }
                    }
                    Spacer()
                    Text(scanMode == nil ? "Import from Photo" : scanMode == .receipt ? "Scan Receipt" : "Import from Bank")
                        .font(.system(size: 17, weight: .bold))
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
                .padding(.bottom, 20)

                if scanMode == nil {
                    modeSelectionView
                } else if showReceiptResult {
                    receiptResultView
                } else if showBankResults {
                    bankResultsView
                } else if let image = selectedImage {
                    imagePreviewView(image: image)
                } else {
                    photoPickerView
                }
            }
        }
        .sheet(isPresented: $showGallery) {
            GalleryPicker(image: $selectedImage, onImageSelected: scanImage)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, onImageSelected: scanImage)
        }
    }

    // MARK: - Mode Selection
    var modeSelectionView: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("What are you scanning?")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)

            Text("Choose the type of image you want to import")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "666666"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    scanMode = .receipt
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "FFE66D").opacity(0.15))
                                .frame(width: 56, height: 56)
                            Text("🧾")
                                .font(.system(size: 28))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scan Receipt")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("One expense — AI reads amount & category")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(hex: "444444"))
                    }
                    .padding(16)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "FFE66D").opacity(0.3), lineWidth: 1)
                    )
                }

                Button {
                    scanMode = .bank
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "4ECDC4").opacity(0.15))
                                .frame(width: 56, height: 56)
                            Text("🏦")
                                .font(.system(size: 28))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import from Bank")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Multiple expenses — works with any bank")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(hex: "444444"))
                    }
                    .padding(16)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "4ECDC4").opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Photo Picker
    var photoPickerView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(scanMode == .receipt ? "🧾" : "🏦")
                .font(.system(size: 64))

            Text(scanMode == .receipt ? "Take or choose a receipt photo" : "Take or choose a bank screenshot")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(Color(hex: "0D0D0D"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "FFE66D"))
                    .cornerRadius(16)
                }

                Button {
                    showGallery = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.fill")
                        Text("Choose from Gallery")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Image Preview
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
                    Text("AI is reading your \(scanMode == .receipt ? "receipt" : "transactions")...")
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
                        Text(scanMode == .receipt ? "Scan Receipt" : "Import Transactions")
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
                            .font(.system(size: 15))
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

    // MARK: - Receipt Result
    var receiptResultView: some View {
        VStack(spacing: 20) {
            Spacer()

            if let amount = scannedAmount {
                VStack(spacing: 16) {
                    Text("✅")
                        .font(.system(size: 48))

                    HStack(spacing: 12) {
                        Text(scannedCategory.emoji)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scannedNote)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text(scannedCategory.rawValue)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: scannedCategory.color))
                        }
                        Spacer()
                        Text("$\(amount, specifier: "%.2f")")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color(hex: "FFE66D"))
                    }
                    .padding(16)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    if let amount = scannedAmount {
                        let expense = Expense(
                            amount: amount,
                            category: scannedCategory,
                            subcategory: "",
                            note: scannedNote,
                            date: Date()
                        )
                        store.addExpense(expense)
                        HapticManager.shared.success()
                        dismiss()
                    }
                } label: {
                    Text("Add Expense ✓")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(hex: "0D0D0D"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "FFE66D"))
                        .cornerRadius(16)
                }

                Button {
                    resetAll()
                } label: {
                    Text("Scan Again")
                        .font(.system(size: 15))
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

    // MARK: - Bank Results
    var bankResultsView: some View {
        VStack(spacing: 0) {
            if duplicateCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color(hex: "FFE66D"))
                    Text("\(duplicateCount) duplicates skipped")
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
                        ImportedTransactionRow(transaction: $transactions[i])
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
                    resetAll()
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

    // MARK: - Functions
    func scanImage() {
        guard let image = selectedImage else { return }
        isScanning = true
        errorMessage = nil

        Task {
            do {
                if scanMode == .receipt {
                    let results = try await gemini.scanReceipt(image: image)
                    await MainActor.run {
                        if let first = results.first {
                            scannedAmount = first.amount
                            scannedCategory = first.category
                            scannedNote = first.note
                        }
                        if results.count > 1 {
                            transactions = results
                            isScanning = false
                            showBankResults = true
                        } else {
                            isScanning = false
                            showReceiptResult = true
                        }
                    }
                } else {
                    let result = try await gemini.scanBankStatement(image: image)
                    let filtered = filterDuplicates(result)
                    await MainActor.run {
                        transactions = filtered.unique
                        duplicateCount = filtered.duplicateCount
                        isScanning = false
                        showBankResults = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not read image. Try a clearer photo."
                    isScanning = false
                }
            }
        }
    }

    func filterDuplicates(_ imported: [ImportedTransaction]) -> (unique: [ImportedTransaction], duplicateCount: Int) {
        var unique: [ImportedTransaction] = []
        var dupCount = 0
        for t in imported {
            let isDuplicate = store.expenses.contains { expense in
                abs(expense.amount - t.amount) < 0.01 &&
                Calendar.current.isDate(expense.date, equalTo: t.date, toGranularity: .day)
            }
            if isDuplicate { dupCount += 1 } else { unique.append(t) }
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

    func resetAll() {
        scanMode = nil
        selectedImage = nil
        isScanning = false
        errorMessage = nil
        showReceiptResult = false
        showBankResults = false
        scannedAmount = nil
        transactions = []
        duplicateCount = 0
    }
}

struct GalleryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: GalleryPicker
        init(_ parent: GalleryPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImageSelected()
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImageSelected()
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
