//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation
import XCTest
@testable import EscapeFromBlindness

class LocalLevelFactoryTests: XCTestCase {
    
    private let expectedNumberOfLevels = 4
    
    func test_build_shouldReturnCorrectNumberOfLevels() {
        let chapters = LocalLevelFactory.build()
        
        XCTAssertEqual(chapters.count, expectedNumberOfLevels)
    }
    
    func test_build_shouldReturnEqualNumberOfEachLevelTypes() {
        let chapters = LocalLevelFactory.build()
        
        XCTAssertEqual(chapters[0].levels.filter { $0 is ClosedQuestionLevel }.count, 4)
        XCTAssertEqual(chapters[1].levels.filter { $0 is RotorLevel }.count, 2)
        XCTAssertEqual(chapters[2].levels.filter { $0 is OpenQuestionLevel }.count, 4)
        XCTAssertEqual(chapters[3].levels.filter { $0 is SearchLevel }.count, 2)
    }
    
    private func translations(_ language: String) -> [String: String] {
        let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language)
        return (path.flatMap { NSDictionary(contentsOfFile: $0) as? [String: String] }) ?? [:]
    }

    func test_everyHint_shouldComeFromTheTranslations() {
        let translatedTexts = Set(translations("en").values).union(translations("fr").values)
        let hints = LocalLevelFactory.build().flatMap { $0.levels }.flatMap { $0.hints }

        XCTAssertFalse(hints.isEmpty)
        for hint in hints {
            XCTAssertTrue(translatedTexts.contains(hint), "Hardcoded hint: \(hint)")
        }
    }

    func test_englishAndFrench_shouldHaveTheSameKeys() {
        let english = Set(translations("en").keys)
        let french = Set(translations("fr").keys)

        XCTAssertFalse(english.isEmpty)
        XCTAssertEqual(english.subtracting(french), [], "Missing in French")
        XCTAssertEqual(french.subtracting(english), [], "Missing in English")
    }

    func test_randomCode_shouldKeepItsLeadingZero() {
        for _ in 0..<200 {
            let code = randomCode(length: 4)
            XCTAssertEqual(code.count, 4, code)
            XCTAssertTrue(code.allSatisfy { $0.isNumber }, code)
        }
    }

    func test_chapter2FirstDoor_shouldOfferThreeDifferentFourDigitCodes() {
        let door = LocalLevelFactory.build()[1].levels[0]

        XCTAssertEqual(door.answers.count, 3)
        XCTAssertEqual(Set(door.answers).count, 3)
        XCTAssertTrue(door.answers.allSatisfy { $0.count == 4 })
        XCTAssertTrue(door.answers.contains("4402"))
    }

}
