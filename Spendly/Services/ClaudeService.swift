//
//  ClaudeService.swift
//  Spendly
//
//  Created by Mahdiar Mazinani on 2026-05-16.
//
import Foundation

class AIService {
    private let apiKey = "YOUR_API_KEY"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func sendMessage(messages: [[String: String]], system: String) async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var allMessages: [[String: String]] = [["role": "system", "content": system]]
        allMessages.append(contentsOf: messages)
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 1024,
            "messages": allMessages
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let rawResponse = String(data: data, encoding: .utf8) ?? "no data"
        print("API Response: \(rawResponse)")
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let text = message["content"] as? String {
            return text
        }
        
        throw NSError(domain: "AIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
}
