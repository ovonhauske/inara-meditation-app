//
//  AIClient.swift
//  inara
//
//  Created by Oscar von Hauske on 1/10/26.
//

import Foundation

enum AIError: Error {
    case invalidURL
    case noData
    case parsingError
    case apiError(String)
}

extension AIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL construction."
        case .noData: return "The API returned no data."
        case .parsingError: return "Could not parse AI response."
        case .apiError(let msg): return "API Error: \(msg)"
        }
    }
}

struct AIClient {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    // MARK: - Public API
    
    /// Generates a short, single-sentence question based on the session context.
    func generateHeadline(context: String) async throws -> String {
        let systemPrompt = """
        You are a gentle, insightful meditation guide.
        Generate a single, short, evocative question (max 10 words) for the user to reflect on after their meditation.
        Context: \(context)
        Do not use quotes.
        """
        
        return try await sendRequest(prompt: systemPrompt)
    }
    
    /// Analyzes the user's reflection to extract somatic patterns.
    /// Returns a JSON string that can be parsed into insights.
    func analyzeReflection(text: String, context: String) async throws -> AnalysisResult {
        let systemPrompt = """
        Analyze this meditation reflection.
        Context: \(context)
        User Reflection: "\(text)"
        
        Return JSON ONLY with this structure:
        {
          "summary": "Updated 100-word bio summarizing their practice and patterns.",
          "insights": [
            {
              "text": "Insight text here",
              "category": "Physical" | "Emotional" | "Environmental",
              "confidence": 0.9
            }
          ]
        }
        """
        
        let jsonString = try await sendRequest(prompt: systemPrompt)
        
        // Clean up markdown code blocks if present (common with Gemini)
        let cleanJSON = jsonString.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        
        guard let data = cleanJSON.data(using: .utf8) else { throw AIError.parsingError }
        return try JSONDecoder().decode(AnalysisResult.self, from: data)
    }
    
    // MARK: - Networking
    
    private func sendRequest(prompt: String) async throws -> String {
        guard var components = URLComponents(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        // Safely add query items
        components.queryItems = [
            URLQueryItem(name: "key", value: Secrets.geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        
        guard let url = components.url else {
            print("Failed to construct URL from components: \(components)")
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("AI Error: \(errorText)")
                throw AIError.apiError(errorText)
            }
            throw AIError.apiError("Unknown error")
        }
        
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return decoded.candidates.first?.content.parts.first?.text ?? ""
    }
}

// MARK: - Models

struct AnalysisResult: Codable {
    let summary: String
    let insights: [InsightResult]
}

struct InsightResult: Codable {
    let text: String
    let category: String
    let confidence: Double
}

// Internal Gemini Response Models
struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}
