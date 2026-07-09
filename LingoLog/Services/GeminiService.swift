import Foundation

enum GeminiServiceError: LocalizedError {
    case missingProxyURL
    case missingSubscriptionProof
    case invalidResponse
    case apiError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Daily Stories is not configured yet. Please add your story generation endpoint."
        case .missingSubscriptionProof:
            return "Your subscription could not be verified. Please restore purchases and try again."
        case .invalidResponse:
            return "Invalid response from the story service."
        case .apiError(let message):
            return message
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

private struct StoryGenerationRequest: Encodable {
    let subscriptionJWS: String
    let languageCode: String
    let languageName: String
    let words: [StoryGenerationWord]
}

private struct StoryGenerationWord: Encodable {
    let word: String
    let translation: String
}

private struct StoryServiceErrorResponse: Decodable {
    let error: String?
}

class GeminiService {
    static let shared = GeminiService()
    
    private let proxyURL: URL?
    
    private init() {
        if let configURL = AppConfig.dailyStoriesFunctionURL {
            self.proxyURL = configURL
            return
        }
        
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dictionary = NSDictionary(contentsOfFile: path),
           let proxyString = dictionary["DailyStoriesFunctionURL"] as? String,
           let proxyURL = URL(string: proxyString),
           !proxyString.isEmpty,
           !proxyString.contains("your-project") {
            self.proxyURL = proxyURL
        } else {
            self.proxyURL = nil
            AppLogger.gemini.error("DailyStoriesFunctionURL missing or not set.")
        }
    }
    
    var isConfigured: Bool {
        proxyURL != nil
    }
    
    func generateStory(
        words: [WordEntry],
        language: String,
        languageName: String,
        subscriptionJWS: String?
    ) async throws -> StoryResponse {
        guard let proxyURL else {
            throw GeminiServiceError.missingProxyURL
        }
        
        guard let subscriptionJWS, !subscriptionJWS.isEmpty else {
            throw GeminiServiceError.missingSubscriptionProof
        }
        
        let requestWords = words.compactMap { word -> StoryGenerationWord? in
            guard let source = word.word, let translation = word.translation else { return nil }
            return StoryGenerationWord(word: source, translation: translation)
        }
        
        let payload = StoryGenerationRequest(
            subscriptionJWS: subscriptionJWS,
            languageCode: language,
            languageName: languageName,
            words: requestWords
        )
        
        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(StoryServiceErrorResponse.self, from: data),
               let message = errorResponse.error,
               !message.isEmpty {
                throw GeminiServiceError.apiError(message)
            }
            
            throw GeminiServiceError.apiError("Story generation failed. Please try again later.")
        }
        
        do {
            return try JSONDecoder().decode(StoryResponse.self, from: data)
        } catch {
            AppLogger.gemini.error("Failed to decode story response: \(error.localizedDescription, privacy: .public)")
            throw GeminiServiceError.decodingError(error.localizedDescription)
        }
    }
}
