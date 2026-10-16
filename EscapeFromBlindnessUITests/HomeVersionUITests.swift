//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
import UIKit

final class HomeVersionUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let versionIdentifier = "home.versionLabel"
    private let versionPattern = #"\d+(\.\d+)*"#
    /// Format de `CFBundleShortVersionString`, suivi éventuellement du build.
    private let marketingVersionPattern = #"^Version \d+\.\d+(\.\d+)?"#
    private let accessibilityPattern = #"^Version \d+\.\d+(\.\d+)?(, build \S+)?$"#

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

    /// XCUITest n'expose pas les traits publiquement : on lit ceux du snapshot quand ils sont disponibles.
    private func traits(of element: XCUIElement) -> UIAccessibilityTraits? {
        guard let snapshot = try? element.snapshot() as? NSObject,
              snapshot.responds(to: NSSelectorFromString("traits")),
              let traits = snapshot.value(forKey: "traits") as? UInt64 else { return nil }
        return UIAccessibilityTraits(rawValue: traits)
    }

    func testAfficherLaVersionSurLAccueil() {
        let app = launchHome()

        let version = versionLabel(in: app)
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        XCTAssertTrue(version.exists)
        XCTAssertTrue(version.label.hasPrefix("Version"), "Libellé inattendu : \(version.label)")
        XCTAssertNotNil(version.label.range(of: marketingVersionPattern, options: .regularExpression),
                        "Numéro de version absent : \(version.label)")

        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThan(version.frame.height, 0)
        XCTAssertTrue(window.contains(version.frame), "Version hors de la fenêtre : \(version.frame) / \(window)")
        XCTAssertGreaterThanOrEqual(version.frame.minY, window.midY)

        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Lancement de l'app, version affichée en bas")
    }

    func testLaVersionNeMasquePasLeContenuDeLAccueil() {
        let app = launchHome()

        let subtitle = app.descendants(matching: .any)["levelSelectionSubtitle"]
        let grid = app.collectionViews.firstMatch
        let version = versionLabel(in: app)
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        XCTAssertTrue(grid.waitForExistence(timeout: timeout))
        XCTAssertTrue(version.waitForExistence(timeout: timeout))

        XCTAssertFalse(version.frame.intersects(subtitle.frame))
        XCTAssertLessThanOrEqual(grid.frame.maxY, version.frame.minY)
        for button in app.buttons.allElementsBoundByIndex where button.exists && button.isHittable {
            XCTAssertFalse(version.frame.intersects(button.frame), "La version croise le bouton \(button.identifier)")
        }
        for cell in grid.cells.allElementsBoundByIndex where cell.exists && cell.isHittable {
            XCTAssertFalse(version.frame.intersects(cell.frame), "La version croise la case \(cell.identifier)")
        }
        AITaskerCapture.captureScreen(nodeId: "AccueilContenu", action: "Accueil chargé, version sous le contenu")

        grid.swipeUp()
        grid.swipeUp()
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        XCTAssertTrue(version.isHittable)
        XCTAssertLessThanOrEqual(grid.frame.maxY, version.frame.minY)
        AITaskerCapture.captureScreen(nodeId: "AccueilBasDePage", action: "Défilement jusqu'en bas de l'accueil")
    }

    func testLaVersionEstLisibleEnModeSombre() {
        let app = launchHome(extraArguments: ["-UITestDarkMode"])

        let version = versionLabel(in: app)
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        assertShowsVersionNumber(version)

        AITaskerCapture.captureScreen(nodeId: "AccueilModeSombre", action: "Lancement en mode sombre")
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

    func testVoiceOverLitLaVersion() {
        let app = launchHome()

        let version = versionLabel(in: app)
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        XCTAssertNotNil(version.label.range(of: accessibilityPattern, options: .regularExpression),
                        "Libellé VoiceOver inattendu : \(version.label)")
        XCTAssertFalse(version.label.contains("("), "VoiceOver lirait une parenthèse : \(version.label)")
        XCTAssertEqual(version.elementType, .staticText)
        XCTAssertFalse(app.buttons[versionIdentifier].exists)
        if let traits = traits(of: version) {
            XCTAssertFalse(traits.contains(.button))
        }

        AITaskerCapture.captureScreen(nodeId: "AccueilAccessibilite", action: "Vérification du libellé VoiceOver de la version")
    }

}
