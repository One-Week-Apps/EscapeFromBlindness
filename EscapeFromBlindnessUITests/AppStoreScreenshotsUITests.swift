//
//  AppStoreScreenshotsUITests.swift
//  Captures the raw App Store screenshots: one screen per kind of level, in French and English,
//  with the VoiceOver reading order next to each image. Skipped unless APPSTORE_SCREENSHOTS_DIR is set.
//

import XCTest

final class AppStoreScreenshotsUITests: XCTestCase {

    private let timeout: TimeInterval = 10

    private var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["APPSTORE_SCREENSHOTS_DIR"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(outputDirectory == nil, "APPSTORE_SCREENSHOTS_DIR is not set")
    }

    func testCaptureFrench() throws {
        try captureAll(language: "fr", locale: "fr_FR")
    }

    func testCaptureEnglish() throws {
        try captureAll(language: "en", locale: "en_US")
    }

    private func captureAll(language: String, locale: String) throws {
        // name, progress (chapter, level) and the tile to open, nil to stay on the level selection.
        let screens: [(name: String, chapter: Int, level: Int, tile: String?)] = [
            ("1_selection", 4, 1, nil),
            ("2_question", 1, 1, "tuileNiveau_1_2"),
            ("3_door", 2, 0, "tuileNiveau_2_1"),
            ("4_riddle", 3, 0, "tuileNiveau_3_1"),
            ("5_search", 4, 0, "tuileNiveau_4_1")
        ]
        for screen in screens {
            let app = launch(language: language, locale: locale, chapter: screen.chapter, level: screen.level)
            if let tile = screen.tile {
                let cell = app.descendants(matching: .any)[tile]
                XCTAssertTrue(cell.waitForExistence(timeout: timeout), "\(tile) not found")
                cell.tap()
                XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
            } else {
                XCTAssertTrue(app.descendants(matching: .any)["levelSelectionSubtitle"].waitForExistence(timeout: timeout))
            }
            sleep(1)
            try save(app: app, name: "\(language)_\(screen.name)")
            app.terminate()
        }

        let app = launch(language: language, locale: locale, chapter: 1, level: 0, extra: ["-UITestActivationVoiceOver"])
        sleep(2)
        try save(app: app, name: "\(language)_6_voiceover")
        app.terminate()
    }

    private func launch(language: String, locale: String, chapter: Int, level: Int, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "\(chapter)",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "\(level)",
            "-AppleLanguages", "(\(language))", "-AppleLocale", locale
        ] + extra
        app.launch()
        return app
    }

    /// UI tests run on the main thread.
    private func save(app: XCUIApplication, name: String) throws {
        try MainActor.assumeIsolated { try write(app: app, name: name) }
    }

    @MainActor
    private func write(app: XCUIApplication, name: String) throws {
        guard let directory = outputDirectory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
        let reading = AITaskerCapture.voiceOverOrder(of: app).joined(separator: "\n")
        try reading.write(to: directory.appendingPathComponent("\(name).txt"), atomically: true, encoding: .utf8)
    }
}
