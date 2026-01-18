import Foundation

enum TranslationServiceError: LocalizedError {
    case missingAPIKey
    case invalidProxyURL
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Translation is unavailable. Please configure a secure proxy or API key."
        case .invalidProxyURL:
            return "Translation proxy URL is invalid."
        }
    }
}

struct TranslationResponse: Codable {
    let translations: [Translation]
}

struct Translation: Codable {
    let text: String
    let to: String
}

struct Language: Identifiable, Codable, Hashable {
    let name: String
    let nativeName: String
    let dir: String
    var id: String { code }
    let code: String
}

struct LanguagesResponse: Codable {
    let translation: [String: LanguageDetail]
}

struct LanguageDetail: Codable {
    let name: String
    let nativeName: String
    let dir: String
}

class TranslationService {
    static let shared = TranslationService()
    
    // API Key or proxy loaded from Secrets.plist
    private let apiKey: String?
    private let proxyURL: URL?
    
    private let region = "eastus"
    private let endpoint = "https://api.cognitive.microsofttranslator.com/translate"
    private let languagesEndpoint = "https://api.cognitive.microsofttranslator.com/languages"
    
    // In-memory cache for languages
    private(set) var cachedLanguages: [Language] = []
    
    private init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dictionary = NSDictionary(contentsOfFile: path),
           let key = dictionary["TranslatorAPIKey"] as? String {
            self.apiKey = key.isEmpty ? nil : key
            if let proxyString = dictionary["TranslatorProxyURL"] as? String,
               !proxyString.isEmpty {
                if let parsedURL = URL(string: proxyString) {
                    self.proxyURL = parsedURL
                } else {
                    self.proxyURL = nil
                    AppLogger.translation.error("TranslatorProxyURL is invalid.")
                }
            } else {
                self.proxyURL = nil
            }
        } else {
            self.apiKey = nil
            self.proxyURL = nil
            AppLogger.translation.error("Secrets.plist missing or TranslatorAPIKey not set.")
        }
    }
    
    func translate(text: String, from sourceLang: String, to targetLang: String) async throws -> String {
        let url: URL
        if let proxyURL = proxyURL {
            guard var components = URLComponents(url: proxyURL, resolvingAgainstBaseURL: false) else {
                throw TranslationServiceError.invalidProxyURL
            }
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: "from", value: sourceLang))
            items.append(URLQueryItem(name: "to", value: targetLang))
            components.queryItems = items
            guard let composedURL = components.url else {
                throw TranslationServiceError.invalidProxyURL
            }
            url = composedURL
        } else {
            guard let apiKey = apiKey, !apiKey.isEmpty else {
                throw TranslationServiceError.missingAPIKey
            }
            guard let endpointURL = URL(string: "\(endpoint)?api-version=3.0&from=\(sourceLang)&to=\(targetLang)") else {
                throw URLError(.badURL)
            }
            url = endpointURL
            _ = apiKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey, proxyURL == nil {
            request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            request.setValue(region, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        }
        
        let body = [["Text": text]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message if available, otherwise generic error
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                AppLogger.translation.error("Translation Error: \(String(describing: errorJson), privacy: .public)")
            }
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode([TranslationResponse].self, from: data)
        guard let translation = result.first?.translations.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        return translation
    }
    

    func fetchLanguages() async throws -> [Language] {
        if !cachedLanguages.isEmpty {
            return cachedLanguages
        }
        
        guard let url = URL(string: "\(languagesEndpoint)?api-version=3.0&scope=translation") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(LanguagesResponse.self, from: data)
        
        let languages = result.translation.map { key, value in
            Language(
                name: value.name,
                nativeName: value.nativeName,
                dir: value.dir,
                code: key
            )
        }.sorted { $0.name < $1.name }
        
        self.cachedLanguages = languages
        return languages
    }
}
