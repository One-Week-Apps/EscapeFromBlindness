//
//  Created by Michael Martinez on 26/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class NiveauxReglagesVoiceOverUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let premiereTuileIdentifier = "tuileNiveau_1_1"
    private let tuilesDuChapitre1Prefix = "tuileNiveau_1_"
    private let boutonReglagesIdentifier = "activationVoiceOver.ouvrirReglages"
    private let consignesIdentifier = "activationVoiceOver.consignes"
    private let texteAgrandi = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let maxBalayages = 10

    override func setUp() {
        continueAfterFailure = false
    }

    private func lancer(_ ecran: String, argumentsSupplementaires: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [ecran, "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"] + argumentsSupplementaires
        app.launch()
        return app
    }

    /// Les tuiles visibles du chapitre 1, regroupées en lignes : une tuile commençant avant le milieu
    /// de la première tuile de la ligne en fait partie.
    private func lignesDuChapitre1(in app: XCUIApplication) -> [[XCUIElement]] {
        let tuiles = app.cells
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", tuilesDuChapitre1Prefix))
            .allElementsBoundByIndex
            .filter { $0.exists && !$0.frame.isEmpty }
            .sorted { $0.frame.minY < $1.frame.minY }
        var lignes: [[XCUIElement]] = []
        for tuile in tuiles {
            if let premiere = lignes.last?.first, tuile.frame.minY < premiere.frame.midY {
                lignes[lignes.count - 1].append(tuile)
            } else {
                lignes.append([tuile])
            }
        }
        return lignes
    }

    private func verifierLignesAlignees(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let lignes = lignesDuChapitre1(in: app)
        XCTAssertFalse(lignes.isEmpty, "Au moins une tuile visible", file: file, line: line)
        for ligne in lignes {
            let minY = ligne[0].frame.minY
            for tuile in ligne {
                XCTAssertEqual(tuile.frame.minY, minY, accuracy: 0.5, "\(tuile.identifier) sur la même ligne", file: file, line: line)
            }
        }
    }

    func testAlignerLesTuilesDesNiveaux() {
        var app = lancer("-UITestChoixNiveau")
        XCTAssertTrue(app.cells[premiereTuileIdentifier].waitForExistence(timeout: timeout))
        verifierLignesAlignees(in: app)
        AITaskerCapture.captureScreen(nodeId: "ChoixNiveau", action: "Tuiles des niveaux alignées")

        app.terminate()
        app = lancer("-UITestChoixNiveau", argumentsSupplementaires: texteAgrandi)
        XCTAssertTrue(app.cells[premiereTuileIdentifier].waitForExistence(timeout: timeout))
        verifierLignesAlignees(in: app)
        AITaskerCapture.captureScreen(nodeId: "ChoixNiveauTexteAgrandi", action: "Tuiles des niveaux alignées en texte agrandi")
    }

    private func verifierBoutonReglages(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let bouton = app.buttons[boutonReglagesIdentifier]
        XCTAssertTrue(bouton.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertEqual(bouton.label, "Ouvrir les Réglages", file: file, line: line)
        XCTAssertGreaterThanOrEqual(bouton.frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, file: file, line: line)

        // Le texte explicatif se lit comme un texte, jamais comme un bouton.
        let consignes = app.staticTexts[consignesIdentifier]
        XCTAssertTrue(consignes.exists, file: file, line: line)
        XCTAssertFalse(app.buttons[consignesIdentifier].exists, file: file, line: line)
        XCTAssertGreaterThan(bouton.frame.minY, consignes.frame.minY, "Le bouton est sous le texte", file: file, line: line)

        // En très grande taille de texte, les consignes défilent jusqu'au bouton.
        var balayages = 0
        while !bouton.isHittable && balayages < maxBalayages {
            app.swipeUp()
            balayages += 1
        }
        XCTAssertTrue(bouton.isHittable, "Bouton visible à l'écran", file: file, line: line)
    }

    func testOuvrirLesReglagesDepuisActivationVoiceOver() {
        var app = lancer("-UITestActivationVoiceOver")
        verifierBoutonReglages(in: app)
        AITaskerCapture.captureScreen(nodeId: "ActivationVoiceOver", action: "Bouton Ouvrir les Réglages sous le texte")

        app.terminate()
        app = lancer("-UITestActivationVoiceOver", argumentsSupplementaires: texteAgrandi)
        verifierBoutonReglages(in: app)
        AITaskerCapture.captureScreen(nodeId: "ActivationVoiceOverTexteAgrandi", action: "Bouton Ouvrir les Réglages en texte agrandi")
    }

}
