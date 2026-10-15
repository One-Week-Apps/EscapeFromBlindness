//
//  Created by Michael Martinez on 21/04/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation
import XCTest
@testable import EscapeFromBlindness

class LoadLevelViewControllerTests: XCTestCase {
    
    var sut: LoadLevelViewController!
    var window: UIWindow!
    var coordinator: AppCoordinatorSpy!
    var accessibilitySpy: AccessibilityNotificationCenterSpy!
    
    override func setUp() {
        super.setUp()
        setupSUT()
    }
    
    override func tearDown() {
        window = nil
        super.tearDown()
    }
    
    private let chapters = LocalLevelFactory.build()
    private let currentChapter = 1
    private let currentLevel = 2
    
    private func setupSUT() {
        window = UIWindow()
        sut = LoadLevelViewController(chapters: chapters, currentChapterIndex: currentChapter, currentLevelIndex: currentLevel)
        self.coordinator = AppCoordinatorSpy()
        sut.coordinator = coordinator
        self.accessibilitySpy = AccessibilityNotificationCenterSpy()
        EscapeFromBlindnessAccessibility.shared = accessibilitySpy
    }
    
    private func loadView() {
        window.addSubview(sut.view)
        RunLoop.current.run(until: Date())
    }
    
    private func unloadView() {
        sut.view.removeFromSuperview()
    }
    
    func test_shouldDisplayOneSectionPerChapter() {
        sut.loadView()
        
        XCTAssertEqual(sut.numberOfSections(in: sut.collectionView), chapters.count)
    }
    
    func test_shouldDisplayAllLevelsInSections() {
        sut.loadView()
        
        for i in 0..<chapters.count {
            XCTAssertEqual(sut.collectionView(sut.collectionView, numberOfItemsInSection: i), chapters[i].levels.count)
        }
    }
    
    func test_unlockedLevelSelected_shouldLoadCorrespondingLevel() {
        sut.loadView()
        
        sut.collectionView(sut.collectionView, didSelectItemAt: IndexPath(item: 2, section: 0))
        
        XCTAssertEqual(coordinator.loadedChapterLevel?.0, 0)
        XCTAssertEqual(coordinator.loadedChapterLevel?.1, 2)
    }
    
    func test_lockedLevelSelected_shouldLoadCorrespondingLevel() {
        sut.loadView()
        
        sut.collectionView(sut.collectionView, didSelectItemAt: IndexPath(item: 2, section: 2))
        
        XCTAssertNil(coordinator.loadedChapterLevel)
    }
    
    func test_viewDidLoad_shouldFocusCurrentLevel() {
        sut.viewDidAppear(false)
        
        XCTAssertEqual(accessibilitySpy.notification, .layoutChanged)
    }

    private func layoutInLightMode(width: CGFloat = 390) {
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 844))
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.view.layoutIfNeeded()
        sut.collectionView.layoutIfNeeded()
    }

    func test_inLightMode_backgroundStaysBlackSoWhiteTitlesRemainVisible() {
        layoutInLightMode()

        XCTAssertEqual(sut.view.backgroundColor, .black)
        XCTAssertEqual(sut.collectionView.backgroundColor, .black)
    }

    func test_inLightMode_currentLevelShowsDarkNumberOnWhiteTile() {
        layoutInLightMode()
        let current = IndexPath(item: currentLevel, section: currentChapter - 1)
        sut.collectionView.scrollToItem(at: current, at: .top, animated: false)
        sut.collectionView.layoutIfNeeded()

        let cell = sut.collectionView.cellForItem(at: current) as? LoadLevelCollectionViewCell

        XCTAssertEqual(cell?.containerView.backgroundColor, .white)
        XCTAssertEqual(cell?.levelLabel.textColor, .black)
    }

    func test_lockedLevelTile_standsOutFromBlackBackground() {
        layoutInLightMode()
        let locked = IndexPath(item: currentLevel + 1, section: currentChapter - 1)
        sut.collectionView.scrollToItem(at: locked, at: .top, animated: false)
        sut.collectionView.layoutIfNeeded()

        let cell = sut.collectionView.cellForItem(at: locked) as? LoadLevelCollectionViewCell

        let tile = cell?.containerView.backgroundColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertNotNil(tile)
        XCTAssertNotEqual(tile, .black)
        XCTAssertNotEqual(tile, .white)
        XCTAssertFalse(cell?.levelLockedImageView.isHidden ?? true)
    }

    func test_grid_staysInsideScreenMarginsWithThreeColumns_onNarrowScreen() {
        layoutInLightMode(width: 320)

        let frames = sut.collectionView.visibleCells.map { sut.view.convert($0.frame, from: sut.collectionView) }

        XCTAssertFalse(frames.isEmpty)
        XCTAssertGreaterThanOrEqual(frames.map(\.minX).min()!, 15)
        XCTAssertLessThanOrEqual(frames.map(\.maxX).max()!, 320 - 15)
        XCTAssertEqual(Set(frames.map { Int($0.minX) }).count, 3)
    }

}
