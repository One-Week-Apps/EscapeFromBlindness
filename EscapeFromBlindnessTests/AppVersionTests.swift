//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

final class AppVersionTests: XCTestCase {

    // MARK: - AppVersion.from(infoDictionary:)

    func test_from_withVersionAndBuild_returnsBoth() {
        let version = AppVersion.from(infoDictionary: [
            "CFBundleShortVersionString": "1.4.2",
            "CFBundleVersion": "87"
        ])

        XCTAssertEqual(version, AppVersion(marketing: "1.4.2", build: "87"))
        XCTAssertEqual(version?.displayText, "Version 1.4.2 (87)")
    }

    func test_from_withoutBuild_returnsVersionOnly() {
        let version = AppVersion.from(infoDictionary: ["CFBundleShortVersionString": "1.4.2"])

        XCTAssertNil(version?.build)
        XCTAssertEqual(version?.displayText, "Version 1.4.2")
    }

    func test_from_withBlankBuild_returnsVersionOnly() {
        let version = AppVersion.from(infoDictionary: [
            "CFBundleShortVersionString": "1.4.2",
            "CFBundleVersion": " "
        ])

        XCTAssertEqual(version?.displayText, "Version 1.4.2")
    }

    func test_from_withBuildEqualToVersion_showsVersionOnly() {
        let version = AppVersion.from(infoDictionary: [
            "CFBundleShortVersionString": "1.4.2",
            "CFBundleVersion": "1.4.2"
        ])

        XCTAssertEqual(version?.displayText, "Version 1.4.2")
        XCTAssertEqual(version?.accessibilityText, "Version 1.4.2")
    }

    func test_from_withoutVersion_returnsNil() {
        XCTAssertNil(AppVersion.from(infoDictionary: ["CFBundleVersion": "87"]))
    }

    func test_from_withBlankVersion_returnsNil() {
        XCTAssertNil(AppVersion.from(infoDictionary: [
            "CFBundleShortVersionString": "",
            "CFBundleVersion": "87"
        ]))
    }

    func test_from_withNilDictionary_returnsNil() {
        XCTAssertNil(AppVersion.from(infoDictionary: nil))
    }

    // MARK: - Textes

    func test_accessibilityText_withVersionAndBuild_readsBuildAsWords() {
        XCTAssertEqual(AppVersion(marketing: "1.4.2", build: "87").accessibilityText, "Version 1.4.2, build 87")
    }

    func test_accessibilityText_withoutBuild_readsVersionOnly() {
        XCTAssertEqual(AppVersion(marketing: "1.4.2", build: nil).accessibilityText, "Version 1.4.2")
    }

    // MARK: - LevelSelectionViewModel

    func test_viewModel_withVersion_exposesDisplayAndAccessibilityTexts() {
        let viewModel = LevelSelectionViewModel(chapters: [], infoDictionary: [
            "CFBundleShortVersionString": "1.4.2",
            "CFBundleVersion": "87"
        ])

        XCTAssertEqual(viewModel.versionText, "Version 1.4.2 (87)")
        XCTAssertEqual(viewModel.versionAccessibilityText, "Version 1.4.2, build 87")
    }

    func test_viewModel_withoutBuild_exposesVersionOnly() {
        let viewModel = LevelSelectionViewModel(chapters: [], infoDictionary: ["CFBundleShortVersionString": "1.4.2"])

        XCTAssertEqual(viewModel.versionText, "Version 1.4.2")
        XCTAssertEqual(viewModel.versionAccessibilityText, "Version 1.4.2")
    }

    func test_viewModel_withoutVersion_exposesNoText() {
        let viewModel = LevelSelectionViewModel(chapters: [], infoDictionary: [:])

        XCTAssertNil(viewModel.versionText)
        XCTAssertNil(viewModel.versionAccessibilityText)
    }

}

final class HomeVersionLabelTests: XCTestCase {

    private var window: UIWindow!

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    private func makeSUT(infoDictionary: [String: Any]? = [
        "CFBundleShortVersionString": "1.4.2",
        "CFBundleVersion": "87"
    ]) -> LoadLevelViewController {
        let sut = LoadLevelViewController(
            chapters: LocalLevelFactory.build(),
            currentChapterIndex: 1,
            currentLevelIndex: 0,
            infoDictionary: infoDictionary
        )
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.view.layoutIfNeeded()
        return sut
    }

    func test_versionLabel_displaysVersionWithStableIdentifier() {
        let sut = makeSUT()

        XCTAssertFalse(sut.versionLabel.isHidden)
        XCTAssertEqual(sut.versionLabel.text, "Version 1.4.2 (87)")
        XCTAssertEqual(sut.versionLabel.accessibilityIdentifier, "home.versionLabel")
    }

    func test_versionLabel_isReadAsStaticTextAndIgnoresTouches() {
        let sut = makeSUT()

        XCTAssertTrue(sut.versionLabel.isAccessibilityElement)
        XCTAssertEqual(sut.versionLabel.accessibilityLabel, "Version 1.4.2, build 87")
        XCTAssertTrue(sut.versionLabel.accessibilityTraits.contains(.staticText))
        XCTAssertFalse(sut.versionLabel.accessibilityTraits.contains(.button))
        XCTAssertFalse(sut.versionLabel.isUserInteractionEnabled)
        XCTAssertTrue(sut.versionLabel.gestureRecognizers?.isEmpty ?? true)
    }

    func test_versionLabel_usesDynamicTypeAndWraps() {
        let sut = makeSUT()

        XCTAssertTrue(sut.versionLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(sut.versionLabel.numberOfLines, 0)
        XCTAssertEqual(sut.versionLabel.textAlignment, .center)
        XCTAssertFalse(sut.versionLabel.adjustsFontSizeToFitWidth)
    }

    func test_versionLabel_usesAccessibleNamedColor() {
        let sut = makeSUT()

        XCTAssertNotNil(UIColor(named: "VersionText"))
        XCTAssertEqual(sut.versionLabel.textColor, UIColor(named: "VersionText"))
    }

    func test_versionLabel_sitsAboveSafeAreaAndBelowGrid() {
        let sut = makeSUT()

        let label = sut.versionLabel.frame
        let grid = sut.collectionView.frame
        let safeBottom = sut.view.bounds.height - sut.view.safeAreaInsets.bottom
        XCTAssertGreaterThan(label.height, 0)
        XCTAssertEqual(label.maxY, safeBottom - 8, accuracy: 0.5)
        XCTAssertEqual(grid.maxY, label.minY - 8, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(label.minX, 16)
        XCTAssertLessThanOrEqual(label.maxX, sut.view.bounds.width - 16)
    }

    func test_versionLabel_isLastAccessibleSubview() {
        let sut = makeSUT()

        XCTAssertTrue(sut.view.subviews.last === sut.versionLabel)
    }

    func test_versionLabel_withoutVersion_isHidden() {
        let sut = makeSUT(infoDictionary: [:])

        XCTAssertTrue(sut.versionLabel.isHidden)
        XCTAssertNil(sut.versionLabel.text)
    }

}
