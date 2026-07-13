import Combine
import Foundation

/// A focused place to learn one language. Vocabulary, reviews, and Daily Stories
/// are scoped to the learning language of the active space.
struct LanguageSpace: Codable, Identifiable, Hashable {
    let id: UUID
    let learningLanguageCode: String
    let meaningLanguageCode: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        learningLanguageCode: String,
        meaningLanguageCode: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.learningLanguageCode = learningLanguageCode
        self.meaningLanguageCode = meaningLanguageCode
        self.createdAt = createdAt
    }

    var learningLanguageName: String {
        Self.name(for: learningLanguageCode)
    }

    var meaningLanguageName: String {
        Self.name(for: meaningLanguageCode)
    }

    var subtitle: String {
        "\(learningLanguageName) ↔ \(meaningLanguageName)"
    }

    private static func name(for code: String) -> String {
        Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code
    }
}

enum LanguageSpaceError: LocalizedError, Equatable {
    case missingLanguage
    case matchingLanguages
    case duplicateLearningLanguage

    var errorDescription: String? {
        switch self {
        case .missingLanguage:
            return "Choose both languages."
        case .matchingLanguages:
            return "Your learning and meaning languages must be different."
        case .duplicateLearningLanguage:
            return "You already have a space for that learning language."
        }
    }
}

@MainActor
final class LanguageSpaceManager: ObservableObject {
    static let shared = LanguageSpaceManager(dataManager: .shared)

    @Published private(set) var spaces: [LanguageSpace]
    @Published private(set) var activeSpaceID: UUID?

    private let defaults: UserDefaults
    private static let spacesKey = "languageSpaces.v1"
    private static let activeSpaceKey = "activeLanguageSpaceID.v1"

    var activeSpace: LanguageSpace? {
        guard let activeSpaceID else { return nil }
        return spaces.first { $0.id == activeSpaceID }
    }

    init(dataManager: DataManager, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedSpaces = Self.loadSpaces(from: defaults, key: Self.spacesKey)
        let resolvedSpaces = savedSpaces.isEmpty
            ? Self.migrateLegacyLanguages(from: dataManager, defaults: defaults)
            : savedSpaces
        self.spaces = resolvedSpaces

        if let savedID = defaults.string(forKey: Self.activeSpaceKey),
           let id = UUID(uuidString: savedID),
           resolvedSpaces.contains(where: { $0.id == id }) {
            activeSpaceID = id
        } else {
            activeSpaceID = resolvedSpaces.first?.id
        }

        if savedSpaces.isEmpty {
            persistSpaces()
        }
        persistActiveSpace()
    }

    func setActiveSpace(_ space: LanguageSpace) {
        guard spaces.contains(space) else { return }
        activeSpaceID = space.id
        persistActiveSpace()
    }

    @discardableResult
    func addSpace(learningLanguageCode: String, meaningLanguageCode: String) throws -> LanguageSpace {
        let learning = learningLanguageCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let meaning = meaningLanguageCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !learning.isEmpty, !meaning.isEmpty else {
            throw LanguageSpaceError.missingLanguage
        }
        guard learning != meaning else {
            throw LanguageSpaceError.matchingLanguages
        }
        guard !spaces.contains(where: { $0.learningLanguageCode == learning }) else {
            throw LanguageSpaceError.duplicateLearningLanguage
        }

        let space = LanguageSpace(
            learningLanguageCode: learning,
            meaningLanguageCode: meaning
        )
        spaces.append(space)
        spaces.sort { $0.learningLanguageName.localizedCaseInsensitiveCompare($1.learningLanguageName) == .orderedAscending }
        persistSpaces()
        setActiveSpace(space)
        return space
    }

    /// Adds a missing space after an explicit legacy-language repair. Existing spaces are
    /// intentionally left unchanged so a user's preferred meaning language is preserved.
    func ensureSpace(learningLanguageCode: String, preferredMeaningLanguageCode: String) {
        guard !learningLanguageCode.isEmpty,
              !spaces.contains(where: { $0.learningLanguageCode == learningLanguageCode }) else { return }
        let meaning = learningLanguageCode == preferredMeaningLanguageCode
            ? Self.fallbackMeaningLanguage(for: learningLanguageCode)
            : preferredMeaningLanguageCode
        _ = try? addSpace(
            learningLanguageCode: learningLanguageCode,
            meaningLanguageCode: meaning
        )
    }

    func resetSpaces() {
        spaces = []
        activeSpaceID = nil
        defaults.removeObject(forKey: Self.spacesKey)
        defaults.removeObject(forKey: Self.activeSpaceKey)
        defaults.removeObject(forKey: "learningLanguage")
        defaults.removeObject(forKey: "meaningLanguage")
    }

    private func persistSpaces() {
        guard let data = try? JSONEncoder().encode(spaces) else { return }
        defaults.set(data, forKey: Self.spacesKey)
    }

    private func persistActiveSpace() {
        defaults.set(activeSpaceID?.uuidString, forKey: Self.activeSpaceKey)
    }

    private static func loadSpaces(from defaults: UserDefaults, key: String) -> [LanguageSpace] {
        guard let data = defaults.data(forKey: key),
              let spaces = try? JSONDecoder().decode([LanguageSpace].self, from: data) else {
            return []
        }
        return spaces
    }

    private static func migrateLegacyLanguages(from dataManager: DataManager, defaults: UserDefaults) -> [LanguageSpace] {
        let legacyLearningLanguage = defaults.string(forKey: "learningLanguage") ?? ""
        let languageCodes = Set(dataManager.getAvailableLanguages() + [legacyLearningLanguage])
            .filter { !$0.isEmpty }
            .sorted()
        let preferredMeaningLanguage = defaults.string(forKey: "meaningLanguage")
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"

        return languageCodes.map { learningCode in
            LanguageSpace(
                learningLanguageCode: learningCode,
                meaningLanguageCode: learningCode == preferredMeaningLanguage
                    ? fallbackMeaningLanguage(for: learningCode)
                    : preferredMeaningLanguage
            )
        }
    }

    private static func fallbackMeaningLanguage(for learningLanguageCode: String) -> String {
        learningLanguageCode == "en" ? "es" : "en"
    }
}
