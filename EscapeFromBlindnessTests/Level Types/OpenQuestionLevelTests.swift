//
//  Created by Michael Martinez on 27/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

class OpenQuestionLevelTests: XCTestCase {

    func test_should_accept_an_open_answer_surrounded_by_extra_spaces_and_a_new_line() {
        let level = OpenQuestionLevel(question: "Q1", validAnswers: ["heo"])

        XCTAssertTrue(level.isSolved(by: ["  \n heo \n  "]))
    }

}
