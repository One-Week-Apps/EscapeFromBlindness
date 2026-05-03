//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation
import XCTest
@testable import EscapeFromBlindness

class LocalLevelFactoryTests: XCTestCase {

    private let expectedNumberOfChapters = 5

    func test_build_shouldReturnCorrectNumberOfChapters() {
        let chapters = LocalLevelFactory.build()
        XCTAssertEqual(chapters.count, expectedNumberOfChapters)
    }

    func test_build_shouldReturnEqualNumberOfEachLevelTypes() {
        let chapters = LocalLevelFactory.build()

        XCTAssertEqual(chapters[0].levels.filter { $0 is ClosedQuestionLevel }.count, 4)
        XCTAssertEqual(chapters[1].levels.filter { $0 is RotorLevel }.count, 2)
        XCTAssertEqual(chapters[2].levels.filter { $0 is OpenQuestionLevel }.count, 4)
        XCTAssertEqual(chapters[3].levels.filter { $0 is SearchLevel }.count, 2)
        XCTAssertEqual(chapters[4].levels.filter { $0 is SwipeGestureLevel }.count, 2)
    }

    func test_build_chapter5Level1_shouldBeVerticalOnly() {
        let chapters = LocalLevelFactory.build()
        let level = chapters[4].levels[0] as! SwipeGestureLevel

        XCTAssertEqual(level.swipeDirections, [.vertical])
        XCTAssertEqual(level.pages.count, 1)
    }

    func test_build_chapter5Level2_shouldHaveVerticalAndHorizontal() {
        let chapters = LocalLevelFactory.build()
        let level = chapters[4].levels[1] as! SwipeGestureLevel

        XCTAssertTrue(level.swipeDirections.contains(.vertical))
        XCTAssertTrue(level.swipeDirections.contains(.horizontal))
        XCTAssertEqual(level.pages.count, 3)
    }
}
