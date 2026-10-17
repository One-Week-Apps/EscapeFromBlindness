//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class HomeVersionLabelUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let versionIdentifier = "homeVersionLabel"
    private let subtitleIdentifier = "levelSelectionSubtitle"
    /// Marge minimale entre la version et le bas de la zone sûre (barre d'accueil).
    private let minimumBottomSpacing: CGFloat = 8

    override func setUp() {
        continueAfterFailure = false
    }

    /// Un joueur qui a déjà progressé arrive sur l'accueil (sélection des niveaux) au lancement.
    private func launchHome(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"
        ] + extraArguments
        app.launch()
        return app
    }

    private func assertVersionVisibleAtBottom(_ version: XCUIElement, in app: XCUIApplication,
                                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(version.exists, file: file, line: line)
        XCTAssertTrue(version.label.hasPrefix("Version"), "Libellé inattendu : \(version.label)", file: file, line: line)
        XCTAssertGreaterThan(version.frame.height, 0, file: file, line: line)

        let window = app.windows.firstMatch.frame
        XCTAssertTrue(window.contains(version.frame), "Version coupée ou hors de l'écran : \(version.frame) / \(window)", file: file, line: line)
        XCTAssertLessThanOrEqual(version.frame.maxY, window.maxY - minimumBottomSpacing, file: file, line: line)

        let grid = app.collectionViews.firstMatch
        if grid.exists {
            XCTAssertLessThanOrEqual(grid.frame.maxY, version.frame.minY, "La grille chevauche la version", file: file, line: line)
        }
    }

    func testAfficherLeNumeroDeVersionSurAccueil() {
        let app = launchHome()

        XCTAssertTrue(app.descendants(matching: .any)[subtitleIdentifier].waitForExistence(timeout: timeout))

        let version = app.staticTexts[versionIdentifier]
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        assertVersionVisibleAtBottom(version, in: app)

        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Numéro de version affiché en bas de l'écran")
    }

    func testAfficherLeNumeroDeVersionAvecGrandePolice() {
        let app = launchHome(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"
        ])

        let version = app.staticTexts[versionIdentifier]
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        assertVersionVisibleAtBottom(version, in: app)

        AITaskerCapture.captureScreen(nodeId: "AccueilGrandePolice", action: "Accueil avec grande police")
    }

}
