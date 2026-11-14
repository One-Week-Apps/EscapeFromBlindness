//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit
import XCTest
@testable import EscapeFromBlindness

class AppCoordinatorTests: XCTestCase {
    
    var sut: AppCoordinator!
    var gameFlowMock: GameFlowMock!
    var userDefaultsMock: UserDefaults!
    var accessibilityNotificationCenterSpy: AccessibilityNotificationCenterSpy!
    
    override func setUp() {
        super.setUp()
        setupSUT()
    }
    
    private func setupSUT() {
        gameFlowMock = GameFlowMock()
        userDefaultsMock = UserDefaultsMock()
        accessibilityNotificationCenterSpy = AccessibilityNotificationCenterSpy()
        
        sut = AppCoordinator(userDefaults: userDefaultsMock, gameFlow: gameFlowMock)
        EscapeFromBlindnessAccessibility.shared = accessibilityNotificationCenterSpy
    }
    
    // MARK: Loading
    func test_IntroScreenNotCompleted_Start_shouldPresentIntroScreen() {
        gameFlowMock.expectedChapter = 0
        
        sut.start(window: UIWindow())
        
        XCTAssertTrue(sut.isPresentIntroControllerCalled)
    }

    func test_IntroScreenCompleted_Start_shouldPresentLoadLevelController() {
        gameFlowMock.expectedChapter = 1

        sut.start(window: UIWindow())

        XCTAssertTrue(sut.isPresentLoadLevelControllerCalled)
    }
    
    // MARK: Saving
    func test_routingToChapterTriggered_shouldSaveChapterIndexToPreferences_IfNewChapter() {
        sut.start(window: UIWindow())
        
        let chapterIndex = 2
        sut.routeToChapter(Chapter(index: chapterIndex, levels: []), isNewChapter: true)
        
        let foundChapter = userDefaultsMock.value(forKey: UserDefaultsKeys.currentChapterIndex.rawValue) as! Int
        let foundLevel = userDefaultsMock.value(forKey: UserDefaultsKeys.currentLevelIndex.rawValue) as! Int
        XCTAssertEqual(foundChapter, chapterIndex)
        XCTAssertEqual(foundLevel, 0)
    }
    
    func test_routingToLevelTriggered_shouldSaveLevelIndexToPreferences() {
        sut.start(window: UIWindow())
        
        gameFlowMock.expectedLevel = 4
        sut.routeToLevel(Level(answers: [], validAnswers: []))
        
        let foundLevel = userDefaultsMock.value(forKey: UserDefaultsKeys.currentLevelIndex.rawValue) as! Int
        XCTAssertEqual(foundLevel, 4)
    }
    
    // MARK: Voice Over Activation Tests
    func test_IntroVCIsPresented_VoiceOverDisabled_shouldNotPresentVoiceOverAlert() {
        sut.presentIntroController(.intro)
        
        accessibilityNotificationCenterSpy.isVoiceOverRunning = false
        sut.voiceOverStatusChanged()
        
        XCTAssertFalse(sut.isVoiceOverAlertActive)
    }
    
    func test_SomeVCIsPresented_VoiceOverDisabled_shouldPresentVoiceOverAlert() {
        sut.presentChapterController(Chapter(index: 0, levels: []))
        
        accessibilityNotificationCenterSpy.isVoiceOverRunning = false
        sut.voiceOverStatusChanged()

        XCTAssertTrue(sut.isVoiceOverAlertActive)
    }

    func test_IntroVCIsPresented_VoiceOverEnabled_shouldNotPresentVoiceOverAlert() {
        sut.presentIntroController(.intro)
        
        accessibilityNotificationCenterSpy.isVoiceOverRunning = true
        sut.voiceOverStatusChanged()

        XCTAssertFalse(sut.isVoiceOverAlertActive)
    }
    
    func test_SomeVCIsPresented_VoiceOverEnabled_shouldNotPresentVoiceOverAlert() {
        sut.presentChapterController(Chapter(index: 0, levels: []))
    
        accessibilityNotificationCenterSpy.isVoiceOverRunning = true
        sut.voiceOverStatusChanged()

        XCTAssertFalse(sut.isVoiceOverAlertActive)
    }
    
    // MARK: Title Display Test
    func test_ClosedQuestionLevelVCIsPresented_navigationBarShouldDisplayCurrentChapterAndLevel() {
        sut.start(window: UIWindow())
        
        let title = "test title"
        gameFlowMock.expectedChapterTitle = title
        let level = ClosedQuestionLevel(question: "", answers: [], validAnswers: [])
        
        sut.presentClosedQuestionController(level)
        
        assertNavBar(chapterName: title, level: 1)
    }
    
    func test_OpenQuestionLevelVCIsPresented_navigationBarShouldDisplayCurrentChapterAndLevel() {
        sut.start(window: UIWindow())
        
        let title = "test title"
        gameFlowMock.expectedChapterTitle = title
        let level = OpenQuestionLevel(question: "", validAnswers: [])
        
        sut.presentOpenQuestionController(level)
        
        assertNavBar(chapterName: title, level: 1)
    }

    func test_RotorQuestionVCIsPresented_navigationBarShouldDisplayCurrentChapterAndLevel() {
        sut.start(window: UIWindow())
        
        let title = "test title"
        gameFlowMock.expectedChapterTitle = title
        let level = RotorLevel(clues: [], answers: [], validAnswers: [])
        
        sut.presentRotorQuestionController(level)
        
        assertNavBar(chapterName: title, level: 1)
    }

    func test_SearchQuestionVCIsPresented_navigationBarShouldDisplayCurrentChapterAndLevel() {
        sut.start(window: UIWindow())
        
        let title = "test title"
        gameFlowMock.expectedChapterTitle = title
        let level = SearchLevel(levelDescription: "", levelActions: [], validActions: [])!
        
        sut.presentSearchQuestionController(level)
        
        assertNavBar(chapterName: title, level: 1)
    }

    private func assertNavBar(chapterName: String, level: Int) {
        XCTAssertEqual(sut.navigationController.viewControllers.first!.navigationItem.title, "\(chapterName)")
        XCTAssertEqual(sut.navigationController.viewControllers.first!.navigationItem.accessibilityLabel, "\(chapterName) - \(L10n.level) \(level)")
    }
    
    // MARK: Wrong Answer Feedback
    private func makeCoordinatorWithRealGameFlow() -> AppCoordinator {
        let levels = [
            ClosedQuestionLevel(question: "Q1", answers: ["A1", "A2"], validAnswers: ["A1"]),
            ClosedQuestionLevel(question: "Q2", answers: ["B1", "B2"], validAnswers: ["B1"])
        ]
        let gameFlow = GameFlow(chapters: [Chapter(index: 1, levels: levels)], currentChapterIndex: 1, currentLevelIndex: 0)
        let coordinator = AppCoordinator(userDefaults: userDefaultsMock, gameFlow: gameFlow)
        coordinator.wrongAnswerAnnouncementDelay = 0
        gameFlow.router = coordinator
        coordinator.start(window: UIWindow())
        return coordinator
    }

    func test_wrongAnswer_shouldBeAnnouncedOnceVoiceOverIsDoneWithTheGesture() {
        let coordinator = makeCoordinatorWithRealGameFlow()
        coordinator.wrongAnswerAnnouncementDelay = 0.05

        coordinator.validate(["A2"])
        XCTAssertNotEqual(announcedText, L10n.wrongAnswer)

        let announced = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) { announced.fulfill() }
        wait(for: [announced], timeout: 0.3)
        XCTAssertEqual(announcedText, L10n.wrongAnswer)
    }

    private var announcedText: String? {
        (accessibilityNotificationCenterSpy.argument as? NSAttributedString)?.string
            ?? accessibilityNotificationCenterSpy.argument as? String
    }

    func test_wrongAnswer_shouldAnnounceItIsNotTheRightAnswer() {
        let coordinator = makeCoordinatorWithRealGameFlow()

        coordinator.validate(["A2"])

        XCTAssertEqual(accessibilityNotificationCenterSpy.notification, .announcement)
        XCTAssertEqual(announcedText, L10n.wrongAnswer)
    }

    func test_wrongAnswer_shouldBeQueuedAfterCurrentSpeech() {
        let coordinator = makeCoordinatorWithRealGameFlow()

        coordinator.validate(["A2"])

        let announcement = accessibilityNotificationCenterSpy.argument as? NSAttributedString
        let queued = announcement?.attribute(.accessibilitySpeechQueueAnnouncement, at: 0, effectiveRange: nil) as? Bool
        XCTAssertEqual(queued, true)
    }

    func test_rightAnswer_shouldNotAnnounceWrongAnswer() {
        let coordinator = makeCoordinatorWithRealGameFlow()

        coordinator.validate(["A1"])

        XCTAssertNotEqual(announcedText, L10n.wrongAnswer)
    }

    // MARK: Replaying A Past Level
    private func makeReplayGameFlow(router: ReplayRouterSpy) -> GameFlow {
        let chapter1 = Chapter(index: 1, levels: [
            ClosedQuestionLevel(question: "Q1", answers: ["A1", "A2"], validAnswers: ["A1"]),
            ClosedQuestionLevel(question: "Q2", answers: ["B1", "B2"], validAnswers: ["B1"])
        ])
        let chapter2 = Chapter(index: 2, levels: [
            ClosedQuestionLevel(question: "Q3", answers: ["C1", "C2"], validAnswers: ["C1"])
        ])
        let gameFlow = GameFlow(chapters: [chapter1, chapter2], currentChapterIndex: 2, currentLevelIndex: 0)
        gameFlow.router = router
        return gameFlow
    }

    func test_replayingPastLevel_rightAnswer_shouldGoToNextLevel() {
        let router = ReplayRouterSpy()
        let gameFlow = makeReplayGameFlow(router: router)

        gameFlow.loadLevel(0, 0)
        gameFlow.validate(["A1"])

        XCTAssertFalse(router.wrongAnswerRouted)
        XCTAssertEqual((router.routedLevels.last as? ClosedQuestionLevel)?.question, "Q2")
    }

    func test_replayingPastLevel_wrongAnswer_shouldRouteToWrongAnswer() {
        let router = ReplayRouterSpy()
        let gameFlow = makeReplayGameFlow(router: router)

        gameFlow.loadLevel(0, 0)
        gameFlow.validate(["A2"])

        XCTAssertTrue(router.wrongAnswerRouted)
    }

    func test_replayingLastLevelOfPastChapter_rightAnswer_shouldNotMarkChapterAsNew() {
        let router = ReplayRouterSpy()
        let gameFlow = makeReplayGameFlow(router: router)

        gameFlow.loadLevel(0, 1)
        gameFlow.validate(["B1"])

        XCTAssertEqual(router.routedChapters.last?.chapter.index, 2)
        XCTAssertEqual(router.routedChapters.last?.isNewChapter, false)
    }

    func test_replayingPastLevel_shouldKeepProgress() {
        let router = ReplayRouterSpy()
        let gameFlow = makeReplayGameFlow(router: router)

        gameFlow.loadLevel(0, 0)
        gameFlow.validate(["A1"])

        XCTAssertEqual(gameFlow.getCurrentChapterIndex(), 2)
        XCTAssertEqual(gameFlow.getCurrentLevelIndex(), 0)
    }

    func test_replayCatchingUpWithProgress_shouldResumeNormalProgression() {
        let router = ReplayRouterSpy()
        let gameFlow = makeReplayGameFlow(router: router)

        gameFlow.loadLevel(0, 1)
        gameFlow.validate(["B1"])
        gameFlow.validateChapter()
        gameFlow.validate(["C1"])

        XCTAssertTrue(router.resultsRouted)
    }


    // MARK: Chapter 2 Rotor Code
    private func enterRotorCode(_ code: String, in coordinator: AppCoordinator) {
        let rotorController = coordinator.navigationController.viewControllers.last as? RotorViewController
        rotorController?.loadViewIfNeeded()
        let rotor = rotorController?.lockedDoorView.accessibilityCustomRotors?.first { $0.name == code }
        XCTAssertNotNil(rotor, "No rotor named \(code)")
        let predicate = UIAccessibilityCustomRotorSearchPredicate()
        predicate.searchDirection = .next
        _ = rotor?.itemSearchBlock(predicate)
    }

    private func makeRealGameCoordinator(chapterIndex: Int, levelIndex: Int) -> (AppCoordinator, GameFlow) {
        let gameFlow = GameFlow(chapters: LocalLevelFactory.build(), currentChapterIndex: chapterIndex, currentLevelIndex: levelIndex)
        let coordinator = AppCoordinator(userDefaults: userDefaultsMock, gameFlow: gameFlow)
        coordinator.wrongAnswerAnnouncementDelay = 0
        gameFlow.router = coordinator
        coordinator.start(window: UIWindow())
        return (coordinator, gameFlow)
    }

    func test_chapter2Level1_enteringCode4402_shouldOpenLevel2() {
        let (coordinator, gameFlow) = makeRealGameCoordinator(chapterIndex: 2, levelIndex: 0)

        gameFlow.loadLevel(1, 0)
        enterRotorCode("4402", in: coordinator)

        XCTAssertNotEqual(announcedText, L10n.wrongAnswer)
        XCTAssertEqual(gameFlow.getCurrentLevelIndex(), 1)
    }

    func test_chapter2Level1_replayed_enteringCode4402_shouldOpenLevel2() {
        let (coordinator, gameFlow) = makeRealGameCoordinator(chapterIndex: 3, levelIndex: 0)

        gameFlow.loadLevel(1, 0)
        enterRotorCode("4402", in: coordinator)

        XCTAssertNotEqual(announcedText, L10n.wrongAnswer)
        XCTAssertTrue(coordinator.navigationController.viewControllers.last is RotorViewController)
    }

    // MARK: Replay After The Game End
    private func makeFinishedGameFlow(router: ReplayRouterSpy) -> GameFlow {
        let gameFlow = makeReplayGameFlow(router: router)
        gameFlow.validateChapter()
        gameFlow.validate(["C1"])
        XCTAssertTrue(router.resultsRouted)
        return gameFlow
    }

    func test_replayAfterTheGameEnd_shouldOpenChapter1WithoutMarkingItAsNew() {
        let router = ReplayRouterSpy()
        let gameFlow = makeFinishedGameFlow(router: router)

        gameFlow.replayFromStart()

        XCTAssertEqual(router.routedChapters.last?.chapter.index, 1)
        XCTAssertEqual(router.routedChapters.last?.isNewChapter, false)
    }

    func test_replayAfterTheGameEnd_shouldStartAtLevel1AndKeepProgress() {
        let router = ReplayRouterSpy()
        let gameFlow = makeFinishedGameFlow(router: router)
        let progress = (gameFlow.getCurrentChapterIndex(), gameFlow.getCurrentLevelIndex())

        gameFlow.replayFromStart()
        gameFlow.validateChapter()
        gameFlow.validate(["A1"])

        XCTAssertEqual((router.routedLevels.last as? ClosedQuestionLevel)?.question, "Q2")
        XCTAssertFalse(router.wrongAnswerRouted)
        XCTAssertEqual(gameFlow.getCurrentChapterIndex(), progress.0)
        XCTAssertEqual(gameFlow.getCurrentLevelIndex(), progress.1)
    }

    func test_replay_shouldOpenTheFirstChapterWithoutTheTutorial() {
        sut.start(window: UIWindow())
        sut.isPresentIntroControllerCalled = false

        sut.replay()

        XCTAssertTrue(gameFlowMock.replayFromStartCalled)
        XCTAssertFalse(sut.isPresentIntroControllerCalled)
    }
}

private class ReplayRouterSpy: Router {
    var routedLevels: [Level] = []
    var routedChapters: [(chapter: Chapter, isNewChapter: Bool)] = []
    var resultsRouted = false
    var wrongAnswerRouted = false

    func routeToChapter(_ chapter: Chapter, isNewChapter: Bool) {
        routedChapters.append((chapter, isNewChapter))
    }

    func routeToLevel(_ level: Level) {
        routedLevels.append(level)
    }

    func routeToResults() {
        resultsRouted = true
    }

    func routeToWrongAnswer() {
        wrongAnswerRouted = true
    }
}
