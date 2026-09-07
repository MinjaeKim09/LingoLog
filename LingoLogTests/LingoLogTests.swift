//
//  LingoLogTests.swift
//  LingoLogTests
//
//  Created by Minjae Kim on 6/18/25.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import LingoLog

struct LingoLogTests {

    @Test func eightDigitHexColorSeparatesARGBChannels() {
        let color = UIColor(Color(hex: "80112233"))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        #expect(abs(red - 17.0 / 255.0) < 0.001)
        #expect(abs(green - 34.0 / 255.0) < 0.001)
        #expect(abs(blue - 51.0 / 255.0) < 0.001)
        #expect(abs(alpha - 128.0 / 255.0) < 0.001)
    }

    @Test func storyQuestionDecodesWithoutAnIdentifier() throws {
        let data = Data("""
        {"question":"What happened?","options":["A","B","C","D"],"correctIndex":2}
        """.utf8)

        let question = try JSONDecoder().decode(StoryQuizQuestion.self, from: data)

        #expect(question.options.count == 4)
        #expect(question.correctIndex == 2)
    }

    @Test func koreanInputNormalizesToAKoreanTerm() throws {
        let pair = try #require(NormalizedVocabularyPair.make(
            input: "친구",
            translatedText: "friend",
            learningLanguageCode: "ko",
            meaningLanguageCode: "en",
            inputSide: .learningLanguage
        ))

        #expect(pair.term == "친구")
        #expect(pair.meaning == "friend")
        #expect(pair.learningLanguageCode == "ko")
    }

    @Test func englishInputNormalizesToTheSameKoreanTerm() throws {
        let pair = try #require(NormalizedVocabularyPair.make(
            input: "friend",
            translatedText: "친구",
            learningLanguageCode: "ko",
            meaningLanguageCode: "en",
            inputSide: .meaningLanguage
        ))

        #expect(pair.term == "친구")
        #expect(pair.meaning == "friend")
        #expect(pair.learningLanguageCode == "ko")
    }

    @Test func matchingLanguagesCannotCreateAVocabularyPair() {
        let pair = NormalizedVocabularyPair.make(
            input: "friend",
            translatedText: "friend",
            learningLanguageCode: "en",
            meaningLanguageCode: "en",
            inputSide: .learningLanguage
        )

        #expect(pair == nil)
    }

    @Test func languageSpaceKeepsTheLearningAndMeaningLanguagesTogether() {
        let space = LanguageSpace(
            learningLanguageCode: "ko",
            meaningLanguageCode: "en"
        )

        #expect(space.learningLanguageCode == "ko")
        #expect(space.meaningLanguageCode == "en")
        #expect(space.subtitle.contains("Korean"))
        #expect(space.subtitle.contains("English"))
    }

    @Test @MainActor func languageSpacesPersistOneActiveSpacePerLearningLanguage() throws {
        let suiteName = "LanguageSpaceManagerTests"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let korean = LanguageSpace(learningLanguageCode: "ko", meaningLanguageCode: "en")
        defaults.set(
            try JSONEncoder().encode([korean]),
            forKey: "languageSpaces.v1"
        )

        let manager = LanguageSpaceManager(dataManager: DataManager(inMemory: true), defaults: defaults)
        let japanese = try manager.addSpace(
            learningLanguageCode: "ja",
            meaningLanguageCode: "en"
        )

        #expect(manager.spaces.count == 2)
        #expect(manager.activeSpaceID == japanese.id)

        do {
            _ = try manager.addSpace(learningLanguageCode: "ko", meaningLanguageCode: "en")
            Issue.record("A duplicate learning language should be rejected.")
        } catch let error as LanguageSpaceError {
            #expect(error == .duplicateLearningLanguage)
        }

        defaults.removePersistentDomain(forName: suiteName)
    }

}
