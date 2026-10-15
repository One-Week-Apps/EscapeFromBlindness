//
//  Created by Michael Martinez on 15/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit

/// iOS 27 exige le cycle de vie UIScene : la fenêtre et le coordinateur naissent ici, plus dans l'AppDelegate.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let chapters = LocalLevelFactory.build()
        let currentChapterIndex = UserDefaults.standard.value(forKey: UserDefaultsKeys.currentChapterIndex.rawValue) as? Int ?? 0
        let currentLevelIndex = UserDefaults.standard.value(forKey: UserDefaultsKeys.currentLevelIndex.rawValue) as? Int ?? 0

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
        window.rootViewController = appCoordinator.rootViewController
        window.makeKeyAndVisible()
    }

}
