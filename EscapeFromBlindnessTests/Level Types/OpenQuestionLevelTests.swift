//
//  Created by Michael Martinez on 27/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

class OpenQuestionLevelTests: XCTestCase {

    func test_should_accept_an_open_answer_followed_by_extra_spaces() {
        let level = OpenQuestionLevel(question: "Q1", validAnswers: ["heo"])

        XCTAssertTrue(level.isSolved(by: ["heo   "]))
    }

    func test_should_accept_an_open_answer_preceded_by_extra_spaces() {
        let level = OpenQuestionLevel(question: "Q1", validAnswers: ["heo"])

        XCTAssertTrue(level.isSolved(by: ["   heo"]))
    }

}
