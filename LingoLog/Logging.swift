import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "LingoLog"
    
    static let app = Logger(subsystem: subsystem, category: "app")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let translation = Logger(subsystem: subsystem, category: "translation")
    static let user = Logger(subsystem: subsystem, category: "user")
    static let gemini = Logger(subsystem: subsystem, category: "gemini")
    static let story = Logger(subsystem: subsystem, category: "story")
}
