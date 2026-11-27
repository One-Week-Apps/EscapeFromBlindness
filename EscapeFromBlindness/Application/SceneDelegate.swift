//
//  Created by Michael Martinez on 15/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit
import os

/// iOS 27 requires the UIScene life cycle: the window and the coordinator are created here, no longer in the AppDelegate.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "LevelSelection")
        let loadLevelsState = signposter.beginInterval("LoadLevels")
        let chapters = LocalLevelFactory.build()
        signposter.endInterval("LoadLevels", loadLevelsState)
        // integer(forKey:) returns 0 when the key is missing, and also reads the progress passed as a launch argument (UI tests).
        var currentChapterIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.currentChapterIndex.rawValue)
        var currentLevelIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.currentLevelIndex.rawValue)
        #if DEBUG
        // UI tests: open the level selection directly, with level 1 of chapter 1 in progress and the next ones locked.
        // `-UITestActivationVoiceOver` starts from the same screen, then opens the VoiceOver activation on top of it.
        if ProcessInfo.processInfo.arguments.contains("-UITestChoixNiveau") || ProcessInfo.processInfo.arguments.contains("-UITestActivationVoiceOver") {
            currentChapterIndex = 1
            currentLevelIndex = 0
        }
        // UI tests: progress on the first open question of the game, opened once the window is visible.
        let openQuestionPosition = ProcessInfo.processInfo.arguments.contains("-UITestReponseOuverte")
            ? Self.firstOpenQuestionPosition(in: chapters)
            : nil
        if let openQuestionPosition {
            currentChapterIndex = openQuestionPosition.chapterIndex + 1
            currentLevelIndex = openQuestionPosition.levelIndex
        }
        #endif

        let gameFlow = GameFlow(
            chapters: chapters,
            currentChapterIndex: currentChapterIndex,
            currentLevelIndex: currentLevelIndex
        )
        let appCoordinator = AppCoordinator(gameFlow: gameFlow)
        gameFlow.router = appCoordinator
        self.appCoordinator = appCoordinator

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        appCoordinator.start(window: window)
        #if DEBUG
        // UI tests: open the game end screen (instructions + Replay button) without playing the whole game.
        if ProcessInfo.processInfo.arguments.contains("-UITestGameEnd") {
            appCoordinator.presentIntroController(.gameEnd)
        }
        #endif
        window.rootViewController = appCoordinator.rootViewController
        window.makeKeyAndVisible()
        #if DEBUG
        // UI tests: open the VoiceOver activation directly, on top of the level selection,
        // once the window is visible so that the presentation succeeds.
        if ProcessInfo.processInfo.arguments.contains("-UITestActivationVoiceOver") {
            DispatchQueue.main.async {
                appCoordinator.showActivateVoiceOverAlert()
            }
        }
        // UI tests: open the end-of-chapter screen (chapter 1) without playing it.
        if ProcessInfo.processInfo.arguments.contains("-UITestChapter"), let firstChapter = chapters.first {
            DispatchQueue.main.async {
                appCoordinator.presentChapterController(firstChapter)
            }
        }
        if let openQuestionPosition {
            DispatchQueue.main.async {
                appCoordinator.loadLevel(openQuestionPosition.chapterIndex, levelIndex: openQuestionPosition.levelIndex)
                (appCoordinator.lastNavigationControllerViewController as? OpenQuestionViewController)?.textField.becomeFirstResponder()
            }
        }
        #endif
    }

    #if DEBUG
    /// Position of the first open question, the chapter index starting at 0.
    private static func firstOpenQuestionPosition(in chapters: [Chapter]) -> (chapterIndex: Int, levelIndex: Int)? {
        for (chapterIndex, chapter) in chapters.enumerated() {
            if let levelIndex = chapter.levels.firstIndex(where: { $0 is OpenQuestionLevel }) {
                return (chapterIndex, levelIndex)
            }
        }
        return nil
    }
    #endif

}
