//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

class SwipeGestureViewControllerTests: XCTestCase {

    var sut: SwipeGestureViewController!
    var window: UIWindow!
    var coordinator: AppCoordinatorSpy!

    override func setUp() {
        super.setUp()
        window = UIWindow()
        coordinator = AppCoordinatorSpy()
    }

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    private func loadView() {
        window.addSubview(sut.view)
        RunLoop.current.run(until: Date())
    }

    // MARK: - Display Tests

    func test_viewDidLoad_shouldDisplayInstruction() {
        let level = SwipeGestureLevel(
            instruction: "Scroll down to find the hidden word",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Secret"]],
            validAnswer: "Secret"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        XCTAssertEqual(sut.instructionLabel.text, "Scroll down to find the hidden word")
    }

    func test_viewDidLoad_verticalLevel_shouldCreateButtonsForEachSection() {
        let level = SwipeGestureLevel(
            instruction: "Scroll",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Section 2", "Section 3"]],
            validAnswer: "Section 3"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        let buttons = sut.scrollView.subviews.compactMap { $0 as? UIButton }
        XCTAssertEqual(buttons.count, 3)
    }

    func test_viewDidLoad_verticalLevel_scrollViewShouldNotHavePagingEnabled() {
        let level = SwipeGestureLevel(
            instruction: "Scroll",
            swipeDirections: [.vertical],
            pages: [["Section 1"]],
            validAnswer: "Section 1"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        XCTAssertFalse(sut.scrollView.isPagingEnabled)
    }

    func test_viewDidLoad_horizontalLevel_scrollViewShouldHavePagingEnabled() {
        let level = SwipeGestureLevel(
            instruction: "Navigate parchments",
            swipeDirections: [.vertical, .horizontal],
            pages: [["p1s1"], ["p2s1"]],
            validAnswer: "p2s1"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        XCTAssertTrue(sut.scrollView.isPagingEnabled)
    }

    // MARK: - Validation Tests

    func test_sectionActivated_shouldCallValidateOnCoordinator() {
        let level = SwipeGestureLevel(
            instruction: "Find it",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Answer"]],
            validAnswer: "Answer"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        let buttons = sut.scrollView.subviews.compactMap { $0 as? UIButton }
        buttons.first?.sendActions(for: .touchUpInside)

        XCTAssertEqual(coordinator.validateAnswers, ["Section 1"])
    }

    func test_validSectionActivated_shouldPassValidAnswerToCoordinator() {
        let level = SwipeGestureLevel(
            instruction: "Find it",
            swipeDirections: [.vertical],
            pages: [["Wrong", "Answer"]],
            validAnswer: "Answer"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        let buttons = sut.scrollView.subviews.compactMap { $0 as? UIButton }
        buttons.last?.sendActions(for: .touchUpInside)

        XCTAssertEqual(coordinator.validateAnswers, ["Answer"])
    }
}
