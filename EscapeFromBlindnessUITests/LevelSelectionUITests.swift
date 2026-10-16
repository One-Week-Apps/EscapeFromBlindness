//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class LevelSelectionUITests: XCTestCase {

    private let expectedSubtitle = "Choisis ton niveau"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Un joueur qui a déjà progressé arrive sur la sélection des niveaux au lancement : c'est le chemin habituel vers cet écran.
    private func launchWithSavedProgress(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR"
        ] + extraArguments
        app.launch()
        return app
    }

    func testAfficherLeSousTitreDeSelectionDesNiveaux() {
        let app = launchWithSavedProgress()

        let grid = app.collectionViews.firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout: 10))
        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Lancement de l'app")

        let subtitle = app.descendants(matching: .any)["levelSelectionSubtitle"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 10))
        XCTAssertEqual(subtitle.label, expectedSubtitle)

        let firstTile = grid.cells.element(boundBy: 0)
        XCTAssertTrue(firstTile.waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(subtitle.frame.maxY, firstTile.frame.minY)
        XCTAssertLessThanOrEqual(subtitle.frame.maxY, grid.frame.minY)
        AITaskerCapture.captureScreen(nodeId: "SelectionDesNiveaux", action: "Affichage du sous-titre au-dessus de la grille")
    }

    func testSousTitreLisibleEnGrandeTaillesDeTexte() {
        let app = launchWithSavedProgress(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"
        ])

        let subtitle = app.descendants(matching: .any)["levelSelectionSubtitle"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 10))
        XCTAssertEqual(subtitle.label, expectedSubtitle)

        let screen = app.windows.firstMatch.frame
        XCTAssertTrue(screen.contains(subtitle.frame))

        let grid = app.collectionViews.firstMatch
        let firstTile = grid.cells.element(boundBy: 0)
        XCTAssertTrue(firstTile.waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(subtitle.frame.maxY, grid.frame.minY)
        XCTAssertLessThanOrEqual(subtitle.frame.maxY, firstTile.frame.minY)
        AITaskerCapture.captureScreen(nodeId: "SelectionDesNiveauxGrandTexte", action: "Sous-titre en taille de texte XL")
    }

}
