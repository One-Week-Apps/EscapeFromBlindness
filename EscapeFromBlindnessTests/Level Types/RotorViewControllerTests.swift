//
//  Created by Michael Martinez on 26/12/2019.
//  Copyright © 2019 michael-martinez. All rights reserved.
//

import Foundation
import XCTest
@testable import EscapeFromBlindness

class RotorViewControllerTests: XCTestCase {
    
    // MARK: - Test Variables
    var sut: RotorViewController!
    var window: UIWindow!
    var coordinator: AppCoordinatorSpy!
    var accessibilitySpy: AccessibilityNotificationCenterSpy!
    
    // MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        setupSUT()
    }
    
    override func tearDown() {
        window = nil
        super.tearDown()
    }
    
    // MARK: Private Methods
    private func setupSUT() {
        window = UIWindow()
        coordinator = AppCoordinatorSpy()
        accessibilitySpy = AccessibilityNotificationCenterSpy()
        EscapeFromBlindnessAccessibility.shared = accessibilitySpy
    }
    
    private func loadView() {
        window.addSubview(sut.view)
        RunLoop.current.run(until: Date())
    }
    
    private func unloadView() {
        sut.view.removeFromSuperview()
    }
    
    // MARK: Tests
    func test_whenViewLoads_shouldDisplayClues() {
        sut = RotorViewController(level: RotorLevel(clues: ["C1", "C2", "C3"], answers: [], validAnswers: []))
        
        loadView()
        
        XCTAssertEqual(sut.clueViews[0].accessibilityLabel, "C1")
        XCTAssertEqual(sut.clueViews[1].accessibilityLabel, "C2")
        XCTAssertEqual(sut.clueViews[2].accessibilityLabel, "C3")
    }
    
    func test_whenViewLoads_shouldDisplayLockedDoorLabelWithRotorOptions_WithCorrectAnswers() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: []))
        
        loadView()
        
        XCTAssertNotNil(sut.lockedDoorView)
        XCTAssertEqual(sut.lockedDoorView.accessibilityCustomRotors![0].name, "A1")
        XCTAssertEqual(sut.lockedDoorView.accessibilityCustomRotors![1].name, "A2")
    }
    
    // MARK: Door Code Actions
    func test_door_shouldOfferEachCodeAsAnAction() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: ["A1"]))

        loadView()

        XCTAssertEqual(sut.lockedDoorView.accessibilityCustomActions?.map { $0.name }, ["A1", "A2"])
    }

    func test_chapter2Doors_rotorOptionsAndActions_shouldBeTheSameCodesInTheSameOrder() {
        let rotorLevels = LocalLevelFactory.build()[1].levels.compactMap { $0 as? RotorLevel }
        XCTAssertEqual(rotorLevels.count, 2)

        for level in rotorLevels {
            sut = RotorViewController(level: level)
            loadView()

            let rotorNames = sut.lockedDoorView.accessibilityCustomRotors?.map { $0.name }
            let actionNames = sut.lockedDoorView.accessibilityCustomActions?.map { $0.name }
            XCTAssertEqual(rotorNames, actionNames)
            XCTAssertEqual(rotorNames, level.answers)
            unloadView()
        }
    }

    func test_doubleTappingACodeAction_shouldTryThatCode() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: ["A1"]))
        sut.coordinator = coordinator
        loadView()

        let action = sut.lockedDoorView.accessibilityCustomActions?.first { $0.name == "A2" }
        let handled = action?.actionHandler?(action!)

        XCTAssertEqual(handled, true)
        XCTAssertEqual(coordinator.validateAnswers, ["A2"])
    }

    func test_door_shouldExplainHowToTryACode() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: ["A1"]))

        loadView()

        XCTAssertEqual(sut.lockedDoorView.accessibilityHint, L10n.doorHint)
    }

    private var spokenMessage: String? {
        accessibilitySpy.argument as? String
    }

    private func waitForHintUnlocks(_ seconds: TimeInterval) {
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 0.2)
    }

    func test_whenViewLoads_withNoHints_shouldIndicateNoHints() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: [], hints: []))

        loadView()
        sut.onHintsButtonTouched()

        XCTAssertEqual(accessibilitySpy.notification, .announcement)
        XCTAssertEqual(spokenMessage, L10n.hintNone)
    }

    func test_whenViewLoads_shouldSpeakFirstHintRightAway() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: [], hints: ["H1", "H2", "H3"]))

        loadView()
        sut.onHintsButtonTouched()

        XCTAssertEqual(accessibilitySpy.notification, .announcement)
        XCTAssertTrue(spokenMessage?.contains("H1") ?? false)
        XCTAssertFalse(spokenMessage?.contains("H2") ?? true)
    }

    func test_whenViewLoads_shouldTellWhenTheNextHintComes() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: [], hints: ["H1", "H2", "H3"]))

        loadView()
        sut.onHintsButtonTouched()

        XCTAssertTrue(spokenMessage?.hasSuffix(L10n.hintNextIn(30)) ?? false, spokenMessage ?? "nil")
    }

    func test_afterHintUnlockDelay_shouldSpeakFirstAndSecondHint() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: [], hints: ["H1", "H2", "H3"]))
        sut.kHintUnlockTimeInterval = 0.05
        loadView()

        waitForHintUnlocks(0.07)
        sut.onHintsButtonTouched()

        XCTAssertTrue(spokenMessage?.contains("H1") ?? false)
        XCTAssertTrue(spokenMessage?.contains("H2") ?? false)
        XCTAssertFalse(spokenMessage?.contains("H3") ?? true)
    }

    func test_whenAllHintsAreUnlocked_shouldNotAnnounceANextHint() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: [], hints: ["H1", "H2"]))
        sut.kHintUnlockTimeInterval = 0.05
        loadView()

        waitForHintUnlocks(0.07)
        sut.onHintsButtonTouched()

        XCTAssertTrue(spokenMessage?.contains("H2") ?? false)
        XCTAssertFalse(spokenMessage?.contains(L10n.hintNextIn(1).components(separatedBy: "1").first!) ?? true)
    }

    func test_menuButton_shouldBeLocalized() {
        sut = RotorViewController(level: RotorLevel(clues: [], answers: ["A1", "A2"], validAnswers: [], hints: []))

        loadView()

        XCTAssertEqual(sut.navigationItem.rightBarButtonItems?.last?.accessibilityLabel, L10n.menu)
    }

    func test_levelOpens_shouldPutVoiceOverOnTheDoor() {
        sut = RotorViewController(level: RotorLevel(clues: ["C1"], answers: ["A1", "A2"], validAnswers: ["A1"]))

        loadView()
        sut.viewDidAppear(false)

        XCTAssertEqual(accessibilitySpy.notification, .screenChanged)
        XCTAssertTrue(accessibilitySpy.argument as? UIView === sut.lockedDoorView)
    }

}
