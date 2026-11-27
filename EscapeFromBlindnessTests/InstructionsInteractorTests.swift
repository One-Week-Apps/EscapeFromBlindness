//
//  Created by Michael Martinez on 07/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

final class InstructionsInteractorTests: XCTestCase {

    func test_instructionInterval_defaultsTo5Seconds() {
        let sut = InstructionsInteractor()

        XCTAssertEqual(sut.instructionInterval, 5)
    }

    func test_instructionInterval_injectedValueDrivesGameEndTimer() {
        let sut = InstructionsViewController.fromXib()
        sut.scenario = .gameEnd
        sut.interactor = InstructionsInteractor(instructionInterval: 0.01)
        sut.loadViewIfNeeded()
        defer { sut.timer?.invalidate() }

        XCTAssertEqual(sut.timer?.timeInterval, 0.01)
    }

    func test_transitionDuration_keepsTheHalfSecondFadeAtTheProductionCadence() {
        let sut = InstructionsInteractor()

        XCTAssertEqual(sut.transitionDuration, 0.5)
    }

    func test_transitionDuration_fitsWithinAFastCadence_soTheLastInstructionIsShownLast() {
        let sut = InstructionsInteractor(instructionInterval: 0.05)

        XCTAssertLessThan(sut.transitionDuration * 2, sut.instructionInterval)
    }

}
