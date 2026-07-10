import FirebaseAppCheck
import Foundation

enum TranslationServiceError: LocalizedError {
    case missingProxyURL
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Translation is not configured yet. Please add the translation service endpoint."
        case .invalidResponse:
            return "Translation returned an invalid response."
        case .apiError(let message):
            return message
        }
    }
}

struct Language: Identifiable, Codable, Hashable {
    let name: String
    let nativeName: String
    let dir: String
    var id: String { code }
    let code: String

    init(code: String, name: String) {
        self.code = code
        self.name = name
        self.nativeName = Self.nativeName(for: code) ?? name
        self.dir = Self.isRightToLeft(code) ? "rtl" : "ltr"
    }

    private static func nativeName(for code: String) -> String? {
        let locale = Locale(identifier: code.replacingOccurrences(of: "-", with: "_"))
        return locale.localizedString(forIdentifier: code)
            ?? locale.localizedString(forLanguageCode: code.components(separatedBy: "-").first ?? code)
    }

    private static func isRightToLeft(_ code: String) -> Bool {
        let primaryCode = code.split(separator: "-", maxSplits: 1).first?.lowercased()
        return ["ar", "arc", "ckb", "dv", "fa", "he", "nqo", "ps", "sd", "ug", "ur", "yi"].contains(primaryCode ?? "")
    }
}

private struct TranslationRequest: Encodable {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
}

private struct TranslationResponse: Decodable {
    let translatedText: String
}

private struct TranslationLanguagesResponse: Decodable {
    let languages: [TranslationLanguage]
}

private struct TranslationLanguage: Decodable {
    let code: String
    let name: String
}

private struct TranslationErrorResponse: Decodable {
    let error: String?
}

final class TranslationService {
    static let shared = TranslationService()

    private let functionURL: URL?

    private(set) var cachedLanguages: [Language] = []

    private init() {
        self.functionURL = AppConfig.translationFunctionURL
        if functionURL == nil {
            AppLogger.translation.error("TranslationFunctionURL is missing or invalid.")
        }
    }

    func translate(text: String, from sourceLang: String, to targetLang: String) async throws -> String {
        guard let functionURL else {
            throw TranslationServiceError.missingProxyURL
        }

        var request = try await authenticatedRequest(url: functionURL, method: "POST")
        request.httpBody = try JSONEncoder().encode(
            TranslationRequest(text: text, sourceLanguage: sourceLang, targetLanguage: targetLang)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        do {
            return try JSONDecoder().decode(TranslationResponse.self, from: data).translatedText
        } catch {
            AppLogger.translation.error("Failed to decode translation response: \(error.localizedDescription, privacy: .public)")
            throw TranslationServiceError.invalidResponse
        }
    }

    func fetchLanguages() async throws -> [Language] {
        if !cachedLanguages.isEmpty {
            return cachedLanguages
        }

        guard let functionURL else {
            throw TranslationServiceError.missingProxyURL
        }

        let request = try await authenticatedRequest(url: functionURL, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        do {
            let response = try JSONDecoder().decode(TranslationLanguagesResponse.self, from: data)
            let languages = response.languages
                .map { Language(code: $0.code, name: $0.name) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            guard !languages.isEmpty else {
                throw TranslationServiceError.invalidResponse
            }
            cachedLanguages = languages
            return languages
        } catch let error as TranslationServiceError {
            throw error
        } catch {
            AppLogger.translation.error("Failed to decode languages response: \(error.localizedDescription, privacy: .public)")
            throw TranslationServiceError.invalidResponse
        }
    }

    private func authenticatedRequest(url: URL, method: String) async throws -> URLRequest {
        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(appCheckToken.token, forHTTPHeaderField: "X-Firebase-AppCheck")
        if method == "POST" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(TranslationErrorResponse.self, from: data),
               let message = errorResponse.error,
               !message.isEmpty {
                throw TranslationServiceError.apiError(message)
            }
            throw TranslationServiceError.apiError("Translation is temporarily unavailable. Please try again later.")
        }
    }
}
