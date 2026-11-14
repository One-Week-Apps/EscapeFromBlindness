//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

final class InstructionsRejouerHintTests: XCTestCase {

    private func makeSUT() -> InstructionsViewController {
        let sut = InstructionsViewController.fromXib()
        sut.scenario = .gameEnd
        sut.interactor = nil
        sut.loadViewIfNeeded()
        return sut
    }

    func test_replayButton_exposedHint_equalsL10nEntry() {
        let sut = makeSUT()

        XCTAssertEqual(sut.replayButton.accessibilityHint, L10n.replayHint)
    }

    func test_replayButton_keepsIdentifierAndTitle() {
        let sut = makeSUT()

        XCTAssertEqual(sut.replayButton.accessibilityIdentifier, "instructions.replayButton")
        XCTAssertEqual(sut.replayButton.title(for: .normal), L10n.replay)
    }

}
