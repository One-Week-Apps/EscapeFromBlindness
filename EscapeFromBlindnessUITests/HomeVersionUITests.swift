//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class HomeVersionLabelUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let versionIdentifier = "home.versionLabel"
    private let subtitleIdentifier = "levelSelectionSubtitle"
    private let lastChapterTitleIdentifier = "levelSelection.chapterTitle.4"
    /// Espacement minimal entre la dernière case et la version.
    private let minimumContentSpacing: CGFloat = 16
    /// Espacement minimal entre la version et la barre d'accueil (bas de la zone sûre, où s'arrête la grille).
    private let minimumHomeIndicatorSpacing: CGFloat = 8
    private let maxSwipes = 6

    override func setUp() {
        continueAfterFailure = false
    }

    /// Le joueur en est au dernier niveau : la case jouable est la dernière, juste au-dessus de la version.
    private func launchHome(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "4",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "1",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"
        ] + extraArguments
        app.launch()
        return app
    }

    /// La version est en pied de grille : on fait défiler jusqu'en bas pour l'afficher.
    private func scrollToVersion(in app: XCUIApplication, grid: XCUIElement) -> XCUIElement {
        let version = app.staticTexts[versionIdentifier]
        var swipes = 0
        while !(version.exists && version.isHittable) && swipes < maxSwipes {
            grid.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        return version
    }

    private func lastCell(in grid: XCUIElement) -> XCUIElement {
        let cells = grid.cells.allElementsBoundByIndex.filter { $0.exists }
        return cells.max { $0.frame.maxY < $1.frame.maxY } ?? grid.cells.firstMatch
    }

    private func assertVersionLaidOut(_ version: XCUIElement, below cell: XCUIElement, in app: XCUIApplication, grid: XCUIElement,
                                      file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(version.label.isEmpty, file: file, line: line)
        XCTAssertFalse(version.frame.intersects(cell.frame), "La version \(version.frame) croise la case \(cell.frame)", file: file, line: line)
        XCTAssertGreaterThanOrEqual(version.frame.minY - cell.frame.maxY, minimumContentSpacing, file: file, line: line)

        let window = app.windows.firstMatch.frame
        XCTAssertTrue(window.contains(version.frame), "Version hors de l'écran : \(version.frame) / \(window)", file: file, line: line)
        XCTAssertLessThanOrEqual(version.frame.maxY, grid.frame.maxY - minimumHomeIndicatorSpacing,
                                 "La version descend sous la zone sûre", file: file, line: line)
    }

    func testAfficherLaVersionSousLaCase() {
        let app = launchHome()

        let grid = app.collectionViews.firstMatch
        XCTAssertTrue(app.descendants(matching: .any)[subtitleIdentifier].waitForExistence(timeout: timeout))
        XCTAssertTrue(grid.waitForExistence(timeout: timeout))

        let version = scrollToVersion(in: app, grid: grid)
        let cell = lastCell(in: grid)
        XCTAssertTrue(cell.waitForExistence(timeout: timeout))
        assertVersionLaidOut(version, below: cell, in: app, grid: grid)
        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Accueil affiché, version visible sous la case")

        // La version ne masque pas la case : elle reste tappable et ouvre son niveau.
        XCTAssertTrue(cell.isHittable)
        cell.tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Case cochée, version toujours visible")
    }

    func testAfficherLaVersionAvecGrandeTaille() {
        let app = launchHome(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        let grid = app.collectionViews.firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout: timeout))

        let version = scrollToVersion(in: app, grid: grid)
        let cell = lastCell(in: grid)
        XCTAssertTrue(cell.waitForExistence(timeout: timeout))
        assertVersionLaidOut(version, below: cell, in: app, grid: grid)

        for cell in grid.cells.allElementsBoundByIndex where cell.exists {
            XCTAssertFalse(version.frame.intersects(cell.frame), "La version croise la case \(cell.frame)")
        }
        let chapterTitle = app.descendants(matching: .any)[lastChapterTitleIdentifier]
        if chapterTitle.exists {
            XCTAssertFalse(version.frame.intersects(chapterTitle.frame))
        }
        let subtitle = app.descendants(matching: .any)[subtitleIdentifier]
        XCTAssertFalse(version.frame.intersects(subtitle.frame))
        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Grande police, version sous le contenu")
    }

}
