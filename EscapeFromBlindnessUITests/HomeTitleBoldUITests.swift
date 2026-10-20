//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class HomeTitleBoldUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let titleIdentifier = "levelSelectionSubtitle"
    private let expectedTitle = "Choisis ton niveau"

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

    func testAfficherLeTitreDeLAccueilEnGras() {
        let app = launchHome()

        let title = app.descendants(matching: .any)[titleIdentifier]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.label, expectedTitle)

        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Titre de l'accueil affiché en gras")
    }

    func testTitreDeLAccueilEnGrasAvecGrandeTaille() {
        let app = launchHome(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"
        ])

        let title = app.descendants(matching: .any)[titleIdentifier]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))

        AITaskerCapture.captureScreen(nodeId: "AccueilGrandeTaille", action: "Titre en gras avec grande police")
    }

}
