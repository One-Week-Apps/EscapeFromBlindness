//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
import UIKit

final class LevelSelectionUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let subtitleIdentifier = "levelSelectionSubtitle"
    private let firstChapterTitleIdentifier = "levelSelection.chapterTitle.1"

    override func setUp() {
        continueAfterFailure = false
    }

    /// A player who already made progress lands on the level selection at launch: the usual path to this screen.
    private func launchLevelSelection(language: [String] = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"],
                                      extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0"
        ] + language + extraArguments
        app.launch()
        return app
    }

    private func subtitle(in app: XCUIApplication) -> XCUIElement {
        return app.descendants(matching: .any)[subtitleIdentifier]
    }

    private func firstChapterTitle(in app: XCUIApplication) -> XCUIElement {
        return app.descendants(matching: .any)[firstChapterTitleIdentifier]
    }

    private func firstCell(in app: XCUIApplication) -> XCUIElement {
        return app.collectionViews.firstMatch.cells.element(boundBy: 0)
    }

    private func assertVerticalOrder(subtitle: XCUIElement, chapterTitle: XCUIElement, firstCell: XCUIElement,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(subtitle.exists, file: file, line: line)
        XCTAssertTrue(chapterTitle.exists, file: file, line: line)
        XCTAssertTrue(firstCell.exists, file: file, line: line)
        XCTAssertLessThanOrEqual(subtitle.frame.maxY, chapterTitle.frame.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(chapterTitle.frame.maxY, firstCell.frame.minY, file: file, line: line)
    }

    /// XCUITest does not expose traits publicly: read them from the snapshot when available.
    private func hasHeaderTrait(_ element: XCUIElement) -> Bool? {
        guard let snapshot = try? element.snapshot() as? NSObject,
              snapshot.responds(to: NSSelectorFromString("traits")),
              let traits = snapshot.value(forKey: "traits") as? UInt64 else { return nil }
        return traits & UIAccessibilityTraits.header.rawValue != 0
    }

    func testAfficherLeSousTitreDeSelectionDesNiveaux() {
        let app = launchLevelSelection()

        let subtitle = subtitle(in: app)
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        AITaskerCapture.captureScreen(nodeId: "SelectionDesNiveaux", action: "Ouverture de l'écran de sélection des niveaux")

        XCTAssertTrue(subtitle.exists)
        XCTAssertEqual(subtitle.label, "Choisis ton niveau")
        if let isHeader = hasHeaderTrait(subtitle) {
            XCTAssertTrue(isHeader)
        }
    }

    func testSousTitreAuDessusDuTitreDuPremierChapitre() {
        let app = launchLevelSelection()

        let subtitle = subtitle(in: app)
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        AITaskerCapture.captureScreen(nodeId: "SelectionDesNiveaux", action: "Écran de sélection affiché")

        let chapterTitle = firstChapterTitle(in: app)
        let firstCell = firstCell(in: app)
        XCTAssertTrue(chapterTitle.waitForExistence(timeout: timeout))
        XCTAssertTrue(firstCell.waitForExistence(timeout: timeout))
        assertVerticalOrder(subtitle: subtitle, chapterTitle: chapterTitle, firstCell: firstCell)

        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThan(subtitle.frame.height, 0)
        XCTAssertTrue(window.contains(subtitle.frame))
        AITaskerCapture.captureScreen(nodeId: "SousTitreEtChapitre1", action: "Sous-titre, titre du chapitre 1 et grille visibles dans l'ordre")
    }

    func testSousTitreEnAnglais() {
        let app = launchLevelSelection(language: ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"])

        let subtitle = subtitle(in: app)
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))

        XCTAssertEqual(subtitle.label, "Choose your level")
        AITaskerCapture.captureScreen(nodeId: "SelectionDesNiveauxEN", action: "Écran de sélection en anglais")
    }

    func testSousTitreAvecGrandeTaillePolice() {
        let app = launchLevelSelection(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"
        ])

        let subtitle = subtitle(in: app)
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))

        let chapterTitle = firstChapterTitle(in: app)
        let firstCell = firstCell(in: app)
        XCTAssertTrue(chapterTitle.waitForExistence(timeout: timeout))
        XCTAssertTrue(firstCell.waitForExistence(timeout: timeout))
        assertVerticalOrder(subtitle: subtitle, chapterTitle: chapterTitle, firstCell: firstCell)
        AITaskerCapture.captureScreen(nodeId: "SelectionDesNiveauxGrandTexte", action: "Écran de sélection en grande taille de police")
    }

}
