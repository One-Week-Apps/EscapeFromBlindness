//
//  Created by Michael Martinez on 15/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit
import os

/// iOS 27 exige le cycle de vie UIScene : la fenêtre et le coordinateur naissent ici, plus dans l'AppDelegate.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "LevelSelection")
        let loadLevelsState = signposter.beginInterval("LoadLevels")
        let chapters = LocalLevelFactory.build()
        signposter.endInterval("LoadLevels", loadLevelsState)
        // integer(forKey:) vaut 0 si la clé manque, et lit aussi la progression passée en argument de lancement (tests UI).
        let currentChapterIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.currentChapterIndex.rawValue)
        let currentLevelIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.currentLevelIndex.rawValue)

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
        #if DEBUG
        // Tests UI : force le mode sombre sans toucher aux réglages du simulateur.
        if ProcessInfo.processInfo.arguments.contains("-UITestDarkMode") {
            window.overrideUserInterfaceStyle = .dark
        }
        #endif
        appCoordinator.start(window: window)
        window.rootViewController = appCoordinator.rootViewController
        window.makeKeyAndVisible()
    }

}
