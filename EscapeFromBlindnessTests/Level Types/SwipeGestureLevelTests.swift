//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

class SwipeGestureLevelTests: XCTestCase {

    func test_init_vertical_shouldSetProperties() {
        let level = SwipeGestureLevel(
            instruction: "Scroll down to find the word",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Secret"]],
            validAnswer: "Secret"
        )

        XCTAssertEqual(level.instruction, "Scroll down to find the word")
        XCTAssertEqual(level.swipeDirections, [.vertical])
        XCTAssertEqual(level.pages, [["Section 1", "Secret"]])
        XCTAssertEqual(level.validAnswer, "Secret")
        XCTAssertEqual(level.validAnswers, ["Secret"])
    }

    func test_init_verticalAndHorizontal_shouldSetProperties() {
        let level = SwipeGestureLevel(
            instruction: "Navigate parchments",
            swipeDirections: [.vertical, .horizontal],
            pages: [["p1s1", "p1s2"], ["p2s1", "ANSWER"]],
            validAnswer: "ANSWER"
        )

        XCTAssertEqual(level.swipeDirections, [.vertical, .horizontal])
        XCTAssertEqual(level.pages.count, 2)
        XCTAssertEqual(level.validAnswers, ["ANSWER"])
    }

    func test_init_withHints_shouldPassHintsToParent() {
        let level = SwipeGestureLevel(
            instruction: "Find it",
            swipeDirections: [.vertical],
            pages: [["Section 1"]],
            validAnswer: "Section 1",
            hints: ["Hint 1", "Hint 2"]
        )

        XCTAssertEqual(level.hints, ["Hint 1", "Hint 2"])
    }
}
