//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

final class InstructionsRejouerHintTests: XCTestCase {

    private let key = "replay_hint"
    private let missing = "__missing__"

    private func localizedValue(language: String) -> String? {
        let appBundle = Bundle(for: InstructionsViewController.self)
        guard let path = appBundle.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return nil }
        return bundle.localizedString(forKey: key, value: missing, table: "Localizable")
    }

    func test_replayHint_isResolvedAndNotEmpty() {
        XCTAssertFalse(L10n.replayHint.isEmpty)
        XCTAssertNotEqual(L10n.replayHint, key)
    }

    func test_replayHint_frenchValue() {
        XCTAssertEqual(localizedValue(language: "fr"), "Relit les instructions depuis le début")
    }

    func test_replayHint_englishValue() {
        XCTAssertEqual(localizedValue(language: "en"), "Reads the instructions again from the start")
    }

    func test_replayButton_hasHintAndIdentifierWithoutChangingTitle() {
        let sut = InstructionsViewController.fromXib()
        sut.scenario = .gameEnd
        sut.interactor = nil
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.replayButton.accessibilityHint, L10n.replayHint)
        XCTAssertEqual(sut.replayButton.accessibilityIdentifier, "instructions.replayButton")
        XCTAssertEqual(sut.replayButton.title(for: .normal), L10n.replay)
    }

}
