import Foundation

enum GeminiServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is not configured. Please add your API key to Secrets.plist."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from the API."
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let message):
            return "Failed to parse story response: \(message)"
        }
    }
}

struct StoryQuizQuestion: Codable, Identifiable {
    let id: UUID
    let question: String
    let options: [String]
    let correctIndex: Int
    
    init(id: UUID = UUID(), question: String, options: [String], correctIndex: Int) {
        self.id = id
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
    }
    
    enum CodingKeys: String, CodingKey {
        case id, question, options, correctIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.question = try container.decode(String.self, forKey: .question)
        self.options = try container.decode([String].self, forKey: .options)
        self.correctIndex = try container.decode(Int.self, forKey: .correctIndex)
    }
}

struct StoryResponse: Codable {
    let title: String
    let story: String
    let questions: [StoryQuizQuestion]
}

struct GeminiAPIResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
}

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey: String?
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
    
    private init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dictionary = NSDictionary(contentsOfFile: path),
           let key = dictionary["GeminiAPIKey"] as? String,
           !key.isEmpty,
           !key.contains("YOUR_") {
            self.apiKey = key
        } else {
            self.apiKey = nil
            AppLogger.gemini.error("Secrets.plist missing or GeminiAPIKey not set.")
        }
    }
    
    var isConfigured: Bool {
        apiKey != nil
    }
    
    func generateStory(words: [WordEntry], language: String, languageName: String) async throws -> StoryResponse {
        guard let apiKey = apiKey else {
            throw GeminiServiceError.missingAPIKey
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiServiceError.invalidURL
        }
        
        let wordList = words.compactMap { word -> String? in
            guard let w = word.word, let t = word.translation else { return nil }
            return "\(w) (\(t))"
        }.joined(separator: ", ")
        
        let prompt = buildPrompt(wordList: wordList, language: language, languageName: languageName)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                AppLogger.gemini.error("Gemini API error: \(message, privacy: .public)")
                throw GeminiServiceError.apiError(message)
            }
            throw GeminiServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
        
        guard let textContent = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiServiceError.invalidResponse
        }
        
        // Parse the JSON response from Gemini
        let storyResponse = try parseStoryResponse(from: textContent)
        
        return storyResponse
    }
    
    private func buildPrompt(wordList: String, language: String, languageName: String) -> String {
        """
        You are a creative language learning assistant. Write a short, engaging story for language learners.

        TASK: Write a short story (200-300 words) in \(languageName) that naturally incorporates the following vocabulary words. The story should be simple enough for intermediate learners but interesting to read.

        VOCABULARY WORDS TO INCLUDE:
        \(wordList)

        REQUIREMENTS:
        1. The story should be written entirely in \(languageName)
        2. Use all the vocabulary words naturally within the story
        3. Keep sentences relatively simple but varied
        4. Create an engaging narrative with a clear beginning, middle, and end
        5. After the story, create 4 multiple-choice comprehension questions about the story content and vocabulary usage

        RESPONSE FORMAT (strict JSON):
        {
            "title": "Story title in \(languageName)",
            "story": "The full story text in \(languageName)...",
            "questions": [
                {
                    "question": "Question text in \(languageName)?",
                    "options": ["Option A", "Option B", "Option C", "Option D"],
                    "correctIndex": 0
                },
                {
                    "question": "Another question in \(languageName)?",
                    "options": ["Option A", "Option B", "Option C", "Option D"],
                    "correctIndex": 2
                },
                {
                    "question": "Third question in \(languageName)?",
                    "options": ["Option A", "Option B", "Option C", "Option D"],
                    "correctIndex": 1
                },
                {
                    "question": "Fourth question in \(languageName)?",
                    "options": ["Option A", "Option B", "Option C", "Option D"],
                    "correctIndex": 3
                }
            ]
        }

        Make sure correctIndex is 0-based (0 for first option, 1 for second, etc.).
        Return ONLY the JSON object, no additional text.
        """
    }
    
    private func parseStoryResponse(from text: String) throws -> StoryResponse {
        // Clean up the text - remove markdown code blocks if present
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedText.hasPrefix("```json") {
            cleanedText = String(cleanedText.dropFirst(7))
        } else if cleanedText.hasPrefix("```") {
            cleanedText = String(cleanedText.dropFirst(3))
        }
        
        if cleanedText.hasSuffix("```") {
            cleanedText = String(cleanedText.dropLast(3))
        }
        
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedText.data(using: .utf8) else {
            throw GeminiServiceError.decodingError("Failed to convert response to data")
        }
        
        do {
            let response = try JSONDecoder().decode(StoryResponse.self, from: data)
            return response
        } catch {
            AppLogger.gemini.error("Failed to decode story response: \(error.localizedDescription, privacy: .public)")
            AppLogger.gemini.debug("Raw response: \(cleanedText, privacy: .public)")
            throw GeminiServiceError.decodingError(error.localizedDescription)
        }
    }
}
