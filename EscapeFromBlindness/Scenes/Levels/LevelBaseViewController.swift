//
//  Created by Michael Martinez on 21/04/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit

class LevelBaseViewController: UIViewController, Coordinated {
    var coordinator: AppCoordinatorProtocol?
    var availableHints: [String] = []
    var hints: [String] = []
    internal var kHintUnlockTimeInterval = 30.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let hintsButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(onHintsButtonTouched))
        hintsButtonItem.accessibilityLabel = L10n.hint
        let homeButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(onHomeButtonTouched))
        homeButtonItem.accessibilityLabel = L10n.menu
        self.navigationItem.rightBarButtonItems = [
            hintsButtonItem,
            homeButtonItem
        ]
        
        startTimer()
    }
    
    /// Element VoiceOver starts on when the level opens: its question, not the navigation bar.
    var initialAccessibilityFocus: Any? {
        return nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let element = initialAccessibilityFocus else { return }

        if isRunningTest {
            EscapeFromBlindnessAccessibility.shared.post(notification: .screenChanged, argument: element)
        } else {
            // Let UIKit announce the new screen first, otherwise VoiceOver lands back on the navigation bar.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                EscapeFromBlindnessAccessibility.shared.post(notification: .screenChanged, argument: element)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    var timer: Timer?
    private var nextHintUnlockDate: Date?

    /// The first hint is available right away, the next ones unlock one by one.
    private func startTimer() {
        guard self.hints.count > 0 else { return }

        unlockNextHint()
        guard self.availableHints.count < self.hints.count else { return }

        nextHintUnlockDate = Date().addingTimeInterval(kHintUnlockTimeInterval)
        timer = Timer.scheduledTimer(withTimeInterval: kHintUnlockTimeInterval, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.unlockNextHint()

            if self.availableHints.count == self.hints.count {
                self.stopTimer()
            } else {
                self.nextHintUnlockDate = Date().addingTimeInterval(self.kHintUnlockTimeInterval)
            }
        })
    }

    private func unlockNextHint() {
        self.availableHints.append(self.hints[self.availableHints.count])
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        nextHintUnlockDate = nil
    }

    @objc internal func onHomeButtonTouched() {
        coordinator?.presentLoadLevelController()
    }
    
    @objc internal func onHintsButtonTouched() {
        let message = hintsMessage()

        if isRunningTest {
            EscapeFromBlindnessAccessibility.shared.post(notification: .announcement, argument: message)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                EscapeFromBlindnessAccessibility.shared.post(notification: .announcement, argument: message)
            }
        }
        
    }
    
    private func hintsMessage() -> String {
        guard self.hints.count > 0 else { return L10n.hintNone }

        var message = ""
        for (index, hint) in self.availableHints.enumerated() {
            message += "\(L10n.hint) \(index + 1): \(hint) . "
        }

        if let nextHintUnlockDate = self.nextHintUnlockDate {
            let secondsLeft = max(1, Int(nextHintUnlockDate.timeIntervalSinceNow.rounded(.up)))
            message += L10n.hintNextIn(secondsLeft)
        }

        return message
    }

}
