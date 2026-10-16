//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
@testable import EscapeFromBlindness

private struct AppVersionProviderStub: AppVersionProviding {
    let appVersion: AppVersion?
}

final class AppVersionTests: XCTestCase {

    // MARK: - AppVersion

    func test_displayText_withVersionAndBuild_showsBuildInParentheses() {
        XCTAssertEqual(AppVersion(version: "1.4.2", build: "87").displayText, "Version 1.4.2 (87)")
    }

    func test_displayText_withoutBuild_showsVersionOnly() {
        XCTAssertEqual(AppVersion(version: "1.4.2", build: nil).displayText, "Version 1.4.2")
    }

    func test_accessibilityText_withVersionAndBuild_readsBuildAsWords() {
        XCTAssertEqual(AppVersion(version: "1.4.2", build: "87").accessibilityText, "Version 1.4.2, build 87")
    }

    func test_accessibilityText_withoutBuild_readsVersionOnly() {
        XCTAssertEqual(AppVersion(version: "1.4.2", build: nil).accessibilityText, "Version 1.4.2")
    }

    // MARK: - BundleAppVersionProvider

    func test_provider_withVersionAndBuild_returnsBoth() {
        let provider = BundleAppVersionProvider(infoDictionary: [
            "CFBundleShortVersionString": "1.4.2",
            "CFBundleVersion": "87"
        ])

        XCTAssertEqual(provider.appVersion, AppVersion(version: "1.4.2", build: "87"))
    }

    func test_provider_withoutBuild_returnsVersionOnly() {
        let provider = BundleAppVersionProvider(infoDictionary: ["CFBundleShortVersionString": "1.4.2"])

        XCTAssertEqual(provider.appVersion, AppVersion(version: "1.4.2", build: nil))
    }

    func test_provider_withBlankBuild_returnsVersionOnly() {
        let provider = BundleAppVersionProvider(infoDictionary: [
            "CFBundleShortVersionString": "1.4.2",
            "CFBundleVersion": " "
        ])

        XCTAssertEqual(provider.appVersion, AppVersion(version: "1.4.2", build: nil))
    }

    func test_provider_withEmptyDictionary_returnsNil() {
        XCTAssertNil(BundleAppVersionProvider(infoDictionary: [:]).appVersion)
    }

    func test_provider_withNilDictionary_returnsNil() {
        XCTAssertNil(BundleAppVersionProvider(infoDictionary: nil).appVersion)
    }

    func test_provider_withBlankVersion_returnsNil() {
        let provider = BundleAppVersionProvider(infoDictionary: [
            "CFBundleShortVersionString": "",
            "CFBundleVersion": "87"
        ])

        XCTAssertNil(provider.appVersion)
    }

    // MARK: - LevelSelectionViewModel

    func test_viewModel_withVersion_exposesDisplayAndAccessibilityTexts() {
        let viewModel = LevelSelectionViewModel(
            chapters: [],
            versionProvider: AppVersionProviderStub(appVersion: AppVersion(version: "1.4.2", build: "87"))
        )

        XCTAssertEqual(viewModel.versionText, "Version 1.4.2 (87)")
        XCTAssertEqual(viewModel.versionAccessibilityText, "Version 1.4.2, build 87")
    }

    func test_viewModel_withEmptyInfoDictionary_exposesNoText() {
        let viewModel = LevelSelectionViewModel(
            chapters: [],
            versionProvider: BundleAppVersionProvider(infoDictionary: [:])
        )

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

    private func makeSUT(appVersion: AppVersion?) -> LoadLevelViewController {
        let sut = LoadLevelViewController(
            chapters: LocalLevelFactory.build(),
            currentChapterIndex: 1,
            currentLevelIndex: 0,
            versionProvider: AppVersionProviderStub(appVersion: appVersion)
        )
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.view.layoutIfNeeded()
        return sut
    }

    func test_versionLabel_displaysVersionWithStableIdentifier() {
        let sut = makeSUT(appVersion: AppVersion(version: "1.4.2", build: "87"))

        XCTAssertFalse(sut.versionLabel.isHidden)
        XCTAssertEqual(sut.versionLabel.text, "Version 1.4.2 (87)")
        XCTAssertEqual(sut.versionLabel.accessibilityIdentifier, "homeVersionLabel")
    }

    func test_versionLabel_isReadAsStaticTextAndIgnoresTouches() {
        let sut = makeSUT(appVersion: AppVersion(version: "1.4.2", build: "87"))

        XCTAssertTrue(sut.versionLabel.isAccessibilityElement)
        XCTAssertEqual(sut.versionLabel.accessibilityLabel, "Version 1.4.2, build 87")
        XCTAssertTrue(sut.versionLabel.accessibilityTraits.contains(.staticText))
        XCTAssertFalse(sut.versionLabel.accessibilityTraits.contains(.button))
        XCTAssertFalse(sut.versionLabel.isUserInteractionEnabled)
    }

    func test_versionLabel_usesDynamicTypeAndWraps() {
        let sut = makeSUT(appVersion: AppVersion(version: "1.4.2", build: "87"))

        XCTAssertTrue(sut.versionLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(sut.versionLabel.numberOfLines, 0)
        XCTAssertEqual(sut.versionLabel.textColor, .secondaryLabel)
    }

    func test_versionLabel_sitsAboveSafeAreaAndBelowGrid() {
        let sut = makeSUT(appVersion: AppVersion(version: "1.4.2", build: "87"))

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
        let sut = makeSUT(appVersion: AppVersion(version: "1.4.2", build: "87"))

        XCTAssertTrue(sut.view.subviews.last === sut.versionLabel)
    }

    func test_versionLabel_withoutVersion_isHidden() {
        let sut = makeSUT(appVersion: nil)

        XCTAssertTrue(sut.versionLabel.isHidden)
        XCTAssertNil(sut.versionLabel.text)
    }

}
