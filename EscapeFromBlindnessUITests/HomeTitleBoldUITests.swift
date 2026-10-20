//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest
import UIKit

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

    /// Part des pixels clairs dans la capture du titre : texte blanc sur fond noir, le gras en allume davantage.
    private func inkRatio(of element: XCUIElement) -> Double {
        guard let cgImage = element.screenshot().image.cgImage else {
            XCTFail("Capture du titre illisible")
            return 0
        }
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn, width * height > 0 else {
            XCTFail("Analyse de la capture du titre impossible")
            return 0
        }
        var lit = 0
        for offset in stride(from: 0, to: pixels.count, by: 4) where (Int(pixels[offset]) + Int(pixels[offset + 1]) + Int(pixels[offset + 2])) / 3 > 127 {
            lit += 1
        }
        return Double(lit) / Double(width * height)
    }

    func testAfficherLeTitreDeLAccueilEnGras() {
        let regularApp = launchHome(extraArguments: ["UI-TESTING", "UI-TESTING-SUBTITLE-REGULAR"])
        let regularTitle = regularApp.descendants(matching: .any)[titleIdentifier]
        XCTAssertTrue(regularTitle.waitForExistence(timeout: timeout))
        let regularInk = inkRatio(of: regularTitle)
        AITaskerCapture.captureScreen(nodeId: "AccueilAvantGras", action: "Avant : titre de l'accueil en graisse normale")
        regularApp.terminate()

        let app = launchHome()
        let title = app.descendants(matching: .any)[titleIdentifier]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.label, expectedTitle)

        let boldInk = inkRatio(of: title)
        XCTAssertGreaterThan(boldInk, regularInk * 1.15, "Le titre n'est pas plus épais qu'en graisse normale (\(boldInk) contre \(regularInk))")

        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Après : titre de l'accueil affiché en gras")
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
