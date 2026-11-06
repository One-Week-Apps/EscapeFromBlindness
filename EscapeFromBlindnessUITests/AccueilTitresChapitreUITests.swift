//
//  Created by Michael Martinez on 06/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class AccueilTitresChapitreUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let firstChapterTitleIdentifier = "levelSelection.chapterTitle.1"
    private let expectedFirstChapterLabel = "Chapitre 1, La Grotte de glace"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Un joueur qui a déjà progressé arrive sur l'accueil (sélection des niveaux) au lancement : pas d'argument supplémentaire.
    private func launchAccueil(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"
        ] + extraArguments
        app.launch()
        return app
    }

    func testAfficherLesTitresDeChapitre() {
        let app = launchAccueil()

        let chapterTitle = app.descendants(matching: .any)[firstChapterTitleIdentifier]
        XCTAssertTrue(chapterTitle.waitForExistence(timeout: timeout))
        // Un seul élément VoiceOver : le libellé « Chapitre 1 » et le nom du chapitre sont lus ensemble.
        XCTAssertEqual(chapterTitle.label, expectedFirstChapterLabel)

        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Titres de chapitre affichés sur deux niveaux")
    }

    func testAfficherLesTitresDeChapitreTexteAgrandi() {
        // Référence en taille standard : hauteur du titre quand le nom tient sur une ligne.
        let standardApp = launchAccueil()
        let standardTitle = standardApp.descendants(matching: .any)[firstChapterTitleIdentifier]
        XCTAssertTrue(standardTitle.waitForExistence(timeout: timeout))
        let hauteurStandard = standardTitle.frame.height
        standardApp.terminate()

        let app = launchAccueil(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        let chapterTitle = app.descendants(matching: .any)[firstChapterTitleIdentifier]
        XCTAssertTrue(chapterTitle.waitForExistence(timeout: timeout))
        XCTAssertEqual(chapterTitle.label, expectedFirstChapterLabel)
        // Le titre reste dans l'écran : il n'est pas poussé hors de la fenêtre.
        XCTAssertTrue(app.frame.contains(chapterTitle.frame), "Le titre doit rester dans l'écran en XXXL")
        // Le texte passe à la ligne au lieu d'être rétréci : la hauteur XXXL doit être strictement supérieure à la standard.
        XCTAssertGreaterThan(chapterTitle.frame.height, hauteurStandard,
                             "La hauteur du titre en XXXL doit dépasser la hauteur standard")

        AITaskerCapture.captureScreen(nodeId: "AccueilTexteAgrandi", action: "Titres de chapitre au Dynamic Type maximal")

        app.terminate()
        let xlApp = launchAccueil(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"
        ])

        let xlTitle = xlApp.descendants(matching: .any)[firstChapterTitleIdentifier]
        XCTAssertTrue(xlTitle.waitForExistence(timeout: timeout))
        XCTAssertEqual(xlTitle.label, expectedFirstChapterLabel)

        AITaskerCapture.captureScreen(nodeId: "AccueilTexteAgrandiXL", action: "Titres de chapitre en taille XL")
    }

}
