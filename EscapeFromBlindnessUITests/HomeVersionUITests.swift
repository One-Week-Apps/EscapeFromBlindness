//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class HomeVersionUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let versionIdentifier = "homeVersionLabel"
    private let versionPattern = #"\d+(\.\d+)*"#

    override func setUp() {
        continueAfterFailure = false
    }

    /// Un joueur qui a déjà progressé arrive sur l'accueil (sélection des niveaux) dès le lancement.
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

    private func versionLabel(in app: XCUIApplication) -> XCUIElement {
        return app.staticTexts[versionIdentifier]
    }

    private func assertShowsVersionNumber(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.label.hasPrefix("Version"), "Libellé inattendu : \(element.label)", file: file, line: line)
        XCTAssertNotNil(element.label.range(of: versionPattern, options: .regularExpression),
                        "Numéro de version absent : \(element.label)", file: file, line: line)
    }

    func testAfficherLaVersionSurLAccueil() {
        let app = launchHome()

        let version = versionLabel(in: app)
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        assertShowsVersionNumber(version)

        let grid = app.collectionViews.firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout: timeout))
        XCTAssertGreaterThan(version.frame.minY, grid.frame.minY)
        XCTAssertLessThanOrEqual(grid.frame.maxY, version.frame.minY)

        XCTAssertGreaterThan(version.frame.height, 0)
        XCTAssertLessThanOrEqual(version.frame.maxY, app.frame.height)

        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Lancement de l'app, version affichée en bas de l'écran")
    }

    func testAfficherLaVersionAvecGrandeTaillePolice() {
        let app = launchHome(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ])

        let version = versionLabel(in: app)
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        assertShowsVersionNumber(version)
        XCTAssertLessThanOrEqual(version.frame.maxY, app.frame.height)

        AITaskerCapture.captureScreen(nodeId: "AccueilGrandePolice", action: "Lancement avec taille de police accessibilité maximale")
    }

    func testAfficherLaVersionEnModeSombre() {
        let app = launchHome(extraArguments: ["-AppleInterfaceStyle", "Dark"])

        let version = versionLabel(in: app)
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        assertShowsVersionNumber(version)

        AITaskerCapture.captureScreen(nodeId: "AccueilModeSombre", action: "Lancement en mode sombre, version visible")
    }

}
