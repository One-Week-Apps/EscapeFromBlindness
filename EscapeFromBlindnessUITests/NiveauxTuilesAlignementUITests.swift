//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class NiveauxTuilesAlignementUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    /// `-UITestChoixNiveau` ouvre directement la sélection des niveaux, chapitre 1 en tête.
    private let premiereTuileIdentifier = "tuileNiveau_1_1"
    private let tuilesDuChapitre1Prefix = "tuileNiveau_1_"
    private let grille: CGFloat = 8
    private let cibleMinimale: CGFloat = 44

    override func setUp() {
        continueAfterFailure = false
    }

    private func lancerNiveaux(argumentsSupplementaires: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestChoixNiveau", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"] + argumentsSupplementaires
        app.launch()
        return app
    }

    /// Les tuiles visibles du chapitre 1, rangées par rang (même origine Y) de haut en bas.
    private func rangsDuChapitre1(in app: XCUIApplication) -> [[XCUIElement]] {
        let tuiles = app.cells
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", tuilesDuChapitre1Prefix))
            .allElementsBoundByIndex
            .filter { $0.exists && !$0.frame.isEmpty }
        let parRang = Dictionary(grouping: tuiles) { Int($0.frame.minY.rounded()) }
        return parRang.keys.sorted().map { y in parRang[y]!.sorted { $0.frame.minX < $1.frame.minX } }
    }

    private func verifierGrilleReguliere(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let rangs = rangsDuChapitre1(in: app)
        let tuiles = rangs.flatMap { $0 }
        XCTAssertGreaterThanOrEqual(tuiles.count, 2, "Au moins deux tuiles visibles", file: file, line: line)
        let taille = tuiles[0].frame.size
        XCTAssertGreaterThanOrEqual(taille.width, cibleMinimale, file: file, line: line)
        XCTAssertGreaterThanOrEqual(taille.height, cibleMinimale, file: file, line: line)

        let colonnes = rangs[0].map(\.frame.minX)
        for rang in rangs {
            let y = rang[0].frame.minY
            for (colonne, tuile) in rang.enumerated() {
                // Même rang : même origine Y et même taille.
                XCTAssertEqual(tuile.frame.minY, y, accuracy: 0.5, file: file, line: line)
                XCTAssertEqual(tuile.frame.width, taille.width, accuracy: 0.5, file: file, line: line)
                XCTAssertEqual(tuile.frame.height, taille.height, accuracy: 0.5, file: file, line: line)
                // Chaque tuile se cale sur la colonne du premier rang : le dernier rang ne s'étire ni ne se centre.
                XCTAssertEqual(tuile.frame.minX, colonnes[colonne], accuracy: 0.5, file: file, line: line)

                let libelle = app.descendants(matching: .any)[identifiantDuLibelle(de: tuile)]
                XCTAssertFalse(libelle.label.isEmpty, "Libellé d'accessibilité de \(tuile.identifier)", file: file, line: line)
                XCTAssertTrue(tuile.frame.contains(libelle.frame), "Le numéro reste dans sa tuile", file: file, line: line)
            }
        }

        if colonnes.count > 1 {
            let ecart = colonnes[1] - colonnes[0] - taille.width
            XCTAssertEqual(ecart.truncatingRemainder(dividingBy: grille), 0, accuracy: 0.5, "Écart horizontal multiple de 8 pt", file: file, line: line)
        }
        if rangs.count > 1 {
            let ecart = rangs[1][0].frame.minY - rangs[0][0].frame.maxY
            XCTAssertEqual(ecart.truncatingRemainder(dividingBy: grille), 0, accuracy: 0.5, "Écart vertical multiple de 8 pt", file: file, line: line)
        }

        // Bords de la grille dans l'écran, à gauche comme à droite.
        let fenetre = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(colonnes[0], fenetre.minX, file: file, line: line)
        XCTAssertLessThanOrEqual(rangs[0].last!.frame.maxX, fenetre.maxX, file: file, line: line)
    }

    /// `tuileNiveau_<chapitre>_<niveau>` porte le numéro `levelSelection.level.<chapitre>.<niveau>`.
    private func identifiantDuLibelle(de tuile: XCUIElement) -> String {
        let numeros = tuile.identifier.dropFirst("tuileNiveau_".count).split(separator: "_")
        return "levelSelection.level.\(numeros.joined(separator: "."))"
    }

    func testAlignerLesTuilesDesNiveaux() {
        let app = lancerNiveaux()

        XCTAssertTrue(app.cells[premiereTuileIdentifier].waitForExistence(timeout: timeout))
        verifierGrilleReguliere(in: app)

        AITaskerCapture.captureScreen(nodeId: "Niveaux", action: "Tuiles alignées")
    }

    /// Le côté des tuiles dépend de la taille du numéro : en très grande taille, la grille perd des colonnes mais reste régulière.
    func testAlignerLesTuilesDesNiveauxEnTexteAgrandi() {
        let app = lancerNiveaux(argumentsSupplementaires: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        XCTAssertTrue(app.cells[premiereTuileIdentifier].waitForExistence(timeout: timeout))
        verifierGrilleReguliere(in: app)

        AITaskerCapture.captureScreen(nodeId: "NiveauxTexteAgrandi", action: "Tuiles alignées en texte agrandi")
    }

}
