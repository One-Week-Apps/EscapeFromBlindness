//
//  Created by Michael Martinez on 26/12/2019.
//  Copyright © 2019 michael-martinez. All rights reserved.
//

import Foundation
import XCTest
@testable import EscapeFromBlindness

class OpenQuestionLevelViewControllerTests: XCTestCase {
    
    // MARK: - Test Variables
    var sut: OpenQuestionViewController!
    var window: UIWindow!
    var coordinator: AppCoordinatorSpy!
    
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
    }
    
    private func loadView() {
        window.addSubview(sut.view)
        RunLoop.current.run(until: Date())
    }
    
    private func unloadView() {
        sut.view.removeFromSuperview()
    }

    @discardableResult
    private func pressReturn() -> Bool? {
        return sut.textField.delegate?.textFieldShouldReturn?(sut.textField)
    }
    
    // MARK: - Tests
    func test_viewDidLoad_withOneQuestion_shouldDisplayQuestion() {
        let level = OpenQuestionLevel(
            question: "Q1",
            validAnswers: ["A1"]
        )
        sut = OpenQuestionViewController(level: level, acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        
        loadView()
        
        XCTAssertEqual(sut.mainLabel.text, "Q1")
    }
    
    func test_viewDidLoad_withOneQuestion_andAnswerWritten_shouldValidateLowercasedAnswer() {
        let level = OpenQuestionLevel(
            question: "Q1",
            validAnswers: ["a1"]
        )
        sut = OpenQuestionViewController(level: level, acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        
        loadView()
        sut.textField.becomeFirstResponder()
        sut.textField.text = "A2é"
        pressReturn()
        
        XCTAssertEqual(coordinator?.validateAnswers, ["a2e"])
    }
    
    func test_viewDidLoad_withOneQuestion_andAnswerWritten_shouldValidateWhitespaceTrimmedAnswer() {
        let level = OpenQuestionLevel(
            question: "Q1",
            validAnswers: ["a1"]
        )
        sut = OpenQuestionViewController(level: level, acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        
        loadView()
        sut.textField.becomeFirstResponder()
        sut.textField.text = "A2e "
        pressReturn()
        
        XCTAssertEqual(coordinator?.validateAnswers, ["a2e"])
    }
    
    func test_viewDidLoad_withOneQuestion_andAnswerWritten_shouldValidateNewlinesTrimmedAnswer() {
        let level = OpenQuestionLevel(
            question: "Q1",
            validAnswers: ["a1"]
        )
        sut = OpenQuestionViewController(level: level, acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        
        loadView()
        sut.textField.becomeFirstResponder()
        sut.textField.text = "A2e\n"
        pressReturn()
        
        XCTAssertEqual(coordinator?.validateAnswers, ["a2e"])
    }
    
    func test_pressingReturn_shouldKeepTheKeyboardSoAWrongAnswerCanBeCorrected() {
        sut = OpenQuestionViewController(level: OpenQuestionLevel(question: "Q1", validAnswers: ["a1"]), acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        loadView()
        sut.textField.text = "wrong"

        let shouldReturn = pressReturn()

        XCTAssertEqual(shouldReturn, false)
        XCTAssertEqual(coordinator.validateAnswers, ["wrong"])
        XCTAssertEqual(sut.textField.text, "wrong")
    }

    func test_leavingTheFieldWithoutReturn_shouldNotTryTheAnswer() {
        sut = OpenQuestionViewController(level: OpenQuestionLevel(question: "Q1", validAnswers: ["a1"]), acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        loadView()

        sut.textField.text = "half typ"
        sut.textField.delegate?.textFieldDidEndEditing?(sut.textField)

        XCTAssertNil(coordinator.validateAnswers)
    }

    func test_answerField_shouldNotAutocorrectAPassword() {
        sut = OpenQuestionViewController(level: OpenQuestionLevel(question: "Q1", validAnswers: ["a1"]), acceptedVerdictDuration: 0.01)
        loadView()

        XCTAssertEqual(sut.textField.autocorrectionType, .no)
        XCTAssertEqual(sut.textField.autocapitalizationType, .none)
        XCTAssertEqual(sut.textField.spellCheckingType, .no)
    }

    func test_secondReturnWhileTheVerdictIsShown_shouldValidateTheAnswerOnlyOnce() {
        sut = OpenQuestionViewController(level: OpenQuestionLevel(question: "Q1", validAnswers: ["a1"]), acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        loadView()
        sut.textField.text = " a1 "

        pressReturn()
        pressReturn()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertEqual(coordinator.validateCallCount, 1)
        XCTAssertEqual(coordinator.validateAnswers, ["a1"])
    }

    func test_levelOpens_shouldPutVoiceOverOnTheQuestion() {
        let spy = AccessibilityNotificationCenterSpy()
        EscapeFromBlindnessAccessibility.shared = spy
        sut = OpenQuestionViewController(level: OpenQuestionLevel(question: "Q1", validAnswers: ["a1"]), acceptedVerdictDuration: 0.01)

        loadView()
        sut.viewDidAppear(false)

        XCTAssertEqual(spy.notification, .screenChanged)
        XCTAssertTrue(spy.argument as? UILabel === sut.mainLabel)
    }

    func test_returnWithAnAnswerSurroundedBySpaces_shouldAnnounceAcceptedToVoiceOver() {
        let spy = AccessibilityNotificationCenterSpy()
        EscapeFromBlindnessAccessibility.shared = spy
        sut = OpenQuestionViewController(level: OpenQuestionLevel(question: "Q1", validAnswers: ["a1"]), acceptedVerdictDuration: 0.01)
        sut.coordinator = coordinator
        loadView()
        sut.textField.text = " a1 "

        pressReturn()

        XCTAssertEqual(spy.notification, .announcement)
        XCTAssertEqual(spy.argument as? String, L10n.openAnswerAccepted)
    }

}
