import Foundation
import SwiftUI
import UIKit

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var userName: String = ""
    @AppStorage("onboarding_do_not_ask_name") var doNotAskName: Bool = false
    
    private let userNameKey = "user_name"
    
    var shouldShowOnboarding: Bool {
        return userName.isEmpty && !doNotAskName
    }
    
    private init() {
        loadUserName()
    }
    
    func loadUserName() {
        if let storedName = UserDefaults.standard.string(forKey: userNameKey) {
            self.userName = storedName
        }
    }
    
    func setUserName(_ name: String) {
        self.userName = name
        UserDefaults.standard.set(name, forKey: userNameKey)
    }
    
    func setDoNotAskAgain(_ value: Bool) {
        self.doNotAskName = value
    }
    
    func getSuggestedName() -> String {
        return extractName(from: UIDevice.current.name) ?? ""
    }
    
    private func extractName(from deviceName: String) -> String? {
        // Common patterns: "Minjae's iPhone", "Minjae's iPad", "Minjae Kim's Device"
        // We look for the possessive "'s" followed by a device type.
        
        let pattern = "^(.*?)(?:'s|'S)\\s+(?:iPhone|iPad|iPod|Device|MacBook|Watch)$"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: deviceName.utf16.count)
            
            if let match = regex.firstMatch(in: deviceName, options: [], range: range) {
                if let nameRange = Range(match.range(at: 1), in: deviceName) {
                    let name = String(deviceName[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return name.isEmpty ? nil : name
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return nil
    }
}
