import Foundation
import UIKit

class GeminiService {
    private let apiKey = "YOUR_API_KEY"
    private let baseURL = "https://api.openai.com/v1/responses"

    func scanReceipt(image: UIImage) async throws -> [ImportedTransaction] {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "GeminiService", code: 0)
        }

        let prompt = """
        Look at this receipt image carefully.

        Extract EVERY individual line item as a separate transaction.
        Do NOT combine items into one total amount.
        Do NOT include subtotal, tax, tip, or grand total rows.

        If you can only see a grand total with no individual items visible, return that single total.

        For each item:
        - amount: price of that specific item as a positive number
        - note: the item name, cleaned up and readable
        - category: exactly one of: food, transport, shopping, entertainment, health, education, bills, other
        - date: use the date printed on the receipt in YYYY-MM-DD format, or today (2026-05-19) if not visible

        Category rules:
        - food: anything edible, restaurants, cafes, groceries
        - health: pharmacy, supplements, medical items
        - shopping: clothing, electronics, general retail
        - other: anything that does not clearly fit above

        Return ONLY this JSON with no extra text:
        {"transactions":[{"amount":4.99,"note":"Large Coffee","category":"food","date":"2026-05-19"}]}
        """

        let jsonText = try await sendToOpenAI(
            imageData: imageData,
            prompt: prompt
        )
        return parseTransactions(from: jsonText)
    }

    func scanBankStatement(image: UIImage) async throws -> [ImportedTransaction] {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "GeminiService", code: 0)
        }

        let prompt = """
        Look at this bank statement screenshot carefully.

        Extract ALL debit, withdrawal, and purchase transactions.

        INCLUDE:
        - Store and restaurant purchases
        - Online purchases
        - Bill payments and subscription charges
        - ATM withdrawals
        - Service fees charged to the account

        DO NOT INCLUDE:
        - Deposits, credits, or refunds
        - Transfers between own accounts
        - Interest earned
        - Opening or closing balance rows
        - Column headers, totals, or summary rows

        For each transaction:
        - amount: positive number even if shown as negative on the statement
        - note: clean readable merchant name — remove bank codes, asterisks, extra numbers
        - category: exactly one of: food, transport, shopping, entertainment, health, education, bills, other
        - date: YYYY-MM-DD format — if year is missing use 2026

        Category rules:
        - food: restaurants, cafes, grocery stores, food delivery (Uber Eats, DoorDash, Skip)
        - transport: Uber, Lyft, gas stations, transit, parking, tolls
        - bills: Netflix, Spotify, Apple, phone, internet, insurance, utilities, gym memberships
        - shopping: Amazon, clothing, electronics, general retail
        - health: pharmacy, doctor, dental, medical
        - entertainment: movies, bars, concerts, gaming, clubs
        - education: tuition, bookstores, online courses
        - other: anything else

        Return ONLY this JSON with no extra text:
        {"transactions":[{"amount":45.99,"note":"Tim Hortons","category":"food","date":"2026-05-16"}]}

        If the image is unreadable, return: {"transactions":[]}
        """

        let jsonText = try await sendToOpenAI(
            imageData: imageData,
            prompt: prompt
        )
        return parseTransactions(from: jsonText)
    }

    private func parseTransactions(from jsonText: String) -> [ImportedTransaction] {
        guard let data = jsonText.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let array = result["transactions"] as? [[String: Any]] else {
            print("GeminiService parse error:", jsonText)
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return array.compactMap { item in
            let amount: Double
            if let d = item["amount"] as? Double { amount = d }
            else if let i = item["amount"] as? Int { amount = Double(i) }
            else { return nil }

            guard amount > 0,
                  let note = item["note"] as? String, !note.isEmpty,
                  let categoryStr = item["category"] as? String,
                  let dateStr = item["date"] as? String else { return nil }

            let date = formatter.date(from: dateStr) ?? Date()
            let category = Category.allCases.first {
                $0.rawValue.lowercased() == categoryStr.lowercased()
            } ?? .other

            return ImportedTransaction(
                amount: amount,
                note: note,
                category: category,
                date: date
            )
        }
    }

    private func sendToOpenAI(imageData: Data, prompt: String) async throws -> String {
        let base64Image = imageData.base64EncodedString()
        let imageURL = "data:image/jpeg;base64,\(base64Image)"

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": [
                [
                    "role": "user",
                    "content": [
                        ["type": "input_text", "text": prompt],
                        ["type": "input_image", "image_url": imageURL]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            print("OpenAI error \(http.statusCode):", String(data: data, encoding: .utf8) ?? "")
            throw NSError(domain: "GeminiService", code: http.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [[String: Any]] else {
            throw NSError(domain: "GeminiService", code: 2)
        }

        for item in output {
            if let content = item["content"] as? [[String: Any]] {
                for part in content {
                    if let text = part["text"] as? String {
                        return text
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }

        throw NSError(domain: "GeminiService", code: 3)
    }
}
