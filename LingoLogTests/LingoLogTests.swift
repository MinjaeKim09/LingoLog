//
//  LingoLogTests.swift
//  LingoLogTests
//
//  Created by Minjae Kim on 6/18/25.
//

import Foundation
import Testing
@testable import LingoLog

struct LingoLogTests {

    @Test func storyQuestionDecodesWithoutAnIdentifier() throws {
        let data = Data("""
        {"question":"What happened?","options":["A","B","C","D"],"correctIndex":2}
        """.utf8)

        let question = try JSONDecoder().decode(StoryQuizQuestion.self, from: data)

        #expect(question.options.count == 4)
        #expect(question.correctIndex == 2)
    }

}
