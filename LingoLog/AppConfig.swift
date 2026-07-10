import Foundation
import os

struct AppConfig {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LingoLog",
        category: "config"
    )
    
    static var privacyPolicyURL: URL? {
        url(forKey: "PrivacyPolicyURL")
    }
    static var termsOfServiceURL: URL? {
        url(forKey: "TermsOfServiceURL")
    }
    static var dailyStoriesFunctionURL: URL? {
        url(forKey: "DailyStoriesFunctionURL")
    }
    static var translationFunctionURL: URL? {
        url(forKey: "TranslationFunctionURL")
    }
    
    private static func url(forKey key: String) -> URL? {
        guard let value = value(forKey: key), !value.isEmpty,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased()
        else { return nil }

        #if DEBUG
        let isAllowed = scheme == "https" || (scheme == "http" && ["localhost", "127.0.0.1"].contains(url.host))
        #else
        let isAllowed = scheme == "https"
        #endif

        guard isAllowed else {
            logger.error("\(key, privacy: .public) must use HTTPS in release builds.")
            return nil
        }
        return url
    }
    
    private static func value(forKey key: String) -> String? {
        if let infoValue = Bundle.main.infoDictionary?[key] as? String, !infoValue.isEmpty {
            return infoValue
        }
        
        guard let url = Bundle.main.url(forResource: "AppConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            logger.warning("AppConfig.plist missing or unreadable.")
            return nil
        }
        
        return plist[key] as? String
    }
}
