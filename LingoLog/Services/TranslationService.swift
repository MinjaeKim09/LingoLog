import Foundation

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
    
    // TODO: In a production app, move these to a secure configuration
    private let apiKey = "***REMOVED***"
    private let region = "eastus"
    private let endpoint = "https://api.cognitive.microsofttranslator.com/translate"
    private let languagesEndpoint = "https://api.cognitive.microsofttranslator.com/languages"
    
    // In-memory cache for languages
    private(set) var cachedLanguages: [Language] = []
    
    private init() {}
    
    func translate(text: String, from sourceLang: String, to targetLang: String) async throws -> String {
        guard let url = URL(string: "\(endpoint)?api-version=3.0&from=\(sourceLang)&to=\(targetLang)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue(region, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        
        let body = [["Text": text]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message if available, otherwise generic error
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                  print("Translation Error: \(errorJson)")
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
