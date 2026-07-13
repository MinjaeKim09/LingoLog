import FirebaseAppCheck
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
    let term: String
    let meaning: String

    enum CodingKeys: String, CodingKey {
        case term = "word"
        case meaning = "translation"
    }
}

private struct StoryServiceErrorResponse: Decodable {
    let error: String?
}

class GeminiService {
    static let shared = GeminiService()
    
    private let proxyURL: URL?
    
    private init() {
        self.proxyURL = AppConfig.dailyStoriesFunctionURL
        if proxyURL == nil {
            AppLogger.gemini.error("DailyStoriesFunctionURL is missing or invalid.")
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
            return StoryGenerationWord(term: source, meaning: translation)
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
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)
        request.setValue(appCheckToken.token, forHTTPHeaderField: "X-Firebase-AppCheck")
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
