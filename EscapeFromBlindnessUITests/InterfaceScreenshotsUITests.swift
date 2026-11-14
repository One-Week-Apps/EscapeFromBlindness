//
//  InterfaceScreenshotsUITests.swift
//  Captures every screen of the app (intro, instructions, VoiceOver alert, chapter end, level selection)
//  at standard, XL and XXXL text sizes, for review on iPhone and iPad.
//  Skipped unless TEST_RUNNER_INTERFACE_SCREENSHOTS_DIR is set.
//

import XCTest

final class InterfaceScreenshotsUITests: XCTestCase {

    private let timeout: TimeInterval = 10

    private var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["INTERFACE_SCREENSHOTS_DIR"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(outputDirectory == nil, "INTERFACE_SCREENSHOTS_DIR is not set")
    }

    /// Text sizes to review: standard, XL and XXXL (accessibility).
    private let sizes: [(name: String, category: String?)] = [
        ("std", nil),
        ("xl", "UICTContentSizeCategoryXL"),
        ("xxxl", "UICTContentSizeCategoryAccessibilityXXXL")
    ]

    func testCaptureFrench() throws {
        try captureAll(language: "fr", locale: "fr_FR")
    }

    func testCaptureEnglish() throws {
        try captureAll(language: "en", locale: "en_US")
    }

    private func captureAll(language: String, locale: String) throws {
        for size in sizes {
            // Intro: chapter index 0 is the first start.
            let intro = launch(language: language, locale: locale, extra: ["-com.accessibility-toolbox.userdefaults.current-chapter-index", "0"], size: size.category)
            XCTAssertTrue(intro.staticTexts.firstMatch.waitForExistence(timeout: timeout))
            sleep(1)
            try save(app: intro, name: "\(language)_\(size.name)_a_intro")
            intro.terminate()

            // Instructions shown at the end of the game.
            let instructions = launch(language: language, locale: locale, extra: ["-UITestGameEnd"], size: size.category)
            sleep(3)
            sleep(1)
            try save(app: instructions, name: "\(language)_\(size.name)_b_instructions")
            instructions.terminate()

            // VoiceOver activation alert on top of the level selection.
            let alert = launch(language: language, locale: locale, extra: ["-UITestActivationVoiceOver"], size: size.category)
            sleep(3)
            try save(app: alert, name: "\(language)_\(size.name)_c_voiceover_alert")
            alert.terminate()

            // End of chapter screen.
            let chapter = launch(language: language, locale: locale, extra: ["-UITestChapter"], size: size.category)
            sleep(3)
            try save(app: chapter, name: "\(language)_\(size.name)_d_chapter")
            chapter.terminate()

            // Level selection, the main screen.
            let selection = launch(language: language, locale: locale, extra: ["-UITestChoixNiveau"], size: size.category)
            XCTAssertTrue(selection.descendants(matching: .any)["levelSelectionSubtitle"].waitForExistence(timeout: timeout))
            sleep(1)
            try save(app: selection, name: "\(language)_\(size.name)_e_selection")
            selection.terminate()
        }
    }

    private func launch(language: String, locale: String, extra: [String], size: String?) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-com.accessibility-toolbox.userdefaults.current-chapter-index", "1", "-com.accessibility-toolbox.userdefaults.current-level-index", "0", "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        if let size {
            arguments += ["-UIPreferredContentSizeCategoryName", size]
        }
        app.launchArguments = arguments + extra
        app.launch()
        return app
    }

    /// UI tests run on the main thread.
    private func save(app: XCUIApplication, name: String) throws {
        try MainActor.assumeIsolated { try write(name: name) }
    }

    @MainActor
    private func write(name: String) throws {
        guard let directory = outputDirectory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
    }
}
