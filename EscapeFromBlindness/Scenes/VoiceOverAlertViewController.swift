//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit
import os

extension VoiceOverAlertViewController: XibLoadable {}

class VoiceOverAlertViewController: UIViewController, Coordinated {
    var coordinator: AppCoordinatorProtocol?
    
    // MARK: - Outlets
    @IBOutlet weak var voiceOverActivationInstructionsView: UIStackView!
    @IBOutlet weak var userCanContinueInstructionsView: UIStackView!
    @IBOutlet weak var continueButton: UIButton!

    @IBOutlet weak var voiceOverActivationInstructionsLabel: UILabel!
    @IBOutlet weak var voiceOverOnSuccessMessageLabel: UILabel!
    
    private static let openSettingsButtonIdentifier = "activationVoiceOver.ouvrirReglages"
    private static let sideMargin: CGFloat = 32
    private static let topMargin: CGFloat = 16
    private static let bottomMargin: CGFloat = 16
    private static let blockSpacing: CGFloat = 16
    private static let iconTopSpacing: CGFloat = 24
    private static let minimumTouchTarget: CGFloat = 44
    private static let instructionsMaximumPointSize: CGFloat = 34
    private static let buttonMaximumPointSize: CGFloat = 28
    private static let instructionsIdentifier = "activationVoiceOver.consignes"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Reglages")

    /// Only button of the activation screen: opens the Settings app, where the user turns VoiceOver on.
    let openSettingsButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = L10n.voOpenSettings
        // White on the black screen background, black text: maximum contrast in both light and dark mode.
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = .black
        configuration.titleLineBreakMode = .byWordWrapping
        // Capped below the explanation text size: that text stays the largest on screen.
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: VoiceOverAlertViewController.buttonMaximumPointSize)
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontSizeToFitWidth = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = VoiceOverAlertViewController.openSettingsButtonIdentifier
        return button
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.voiceOverActivationInstructionsLabel.text = L10n.vo1
        self.voiceOverOnSuccessMessageLabel.text = L10n.vo2
        self.continueButton.setTitle(L10n.go, for: .normal)
        setupOpenSettingsButton()
    }

    /// Places "Open Settings" below the explanation text. The instructions scroll: at very large text sizes,
    /// the button stays reachable instead of going off screen.
    private func setupOpenSettingsButton() {
        let instructionsLabel = self.voiceOverActivationInstructionsLabel!
        // On iPad the explanation is set larger, with its cap raised by the same factor.
        instructionsLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: instructionsLabel.font.withSize(instructionsLabel.font.pointSize * UIFont.iPadSizeFactor),
            maximumPointSize: VoiceOverAlertViewController.instructionsMaximumPointSize * UIFont.iPadSizeFactor
        )
        instructionsLabel.adjustsFontForContentSizeCategory = true
        instructionsLabel.accessibilityIdentifier = VoiceOverAlertViewController.instructionsIdentifier

        let stackView = self.voiceOverActivationInstructionsView!
        stackView.insertArrangedSubview(self.openSettingsButton, at: stackView.arrangedSubviews.firstIndex(of: instructionsLabel)! + 1)
        stackView.spacing = VoiceOverAlertViewController.blockSpacing
        stackView.setCustomSpacing(VoiceOverAlertViewController.iconTopSpacing, after: self.openSettingsButton)
        self.openSettingsButton.addTarget(self, action: #selector(onOpenSettingsButtonTouched), for: .touchUpInside)

        // Removing the stack from the view clears its xib constraints: text, button and icon scroll, aligned to the top.
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.removeFromSuperview()
        scrollView.addSubview(stackView)
        self.view.insertSubview(scrollView, at: 0)

        let safeArea = self.view.safeAreaLayoutGuide
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        // Preferred, not required: on a tall screen the column is centred; when the text needs more room, it stretches to the content.
        let stackWidth = stackView.widthAnchor.constraint(equalTo: content.widthAnchor, constant: -2 * VoiceOverAlertViewController.sideMargin)
        stackWidth.priority = .defaultHigh
        let stackCentering = stackView.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        stackCentering.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            // The content is at least as tall as the screen, so that the column can be centred in it.
            content.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor),
            // Centred in the screen, in a column no wider than the readable width (iPad), between the margins (iPhone).
            stackView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: self.view.readableContentGuide.widthAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: VoiceOverAlertViewController.topMargin),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -VoiceOverAlertViewController.bottomMargin),
            stackWidth,
            stackCentering,
            // The stack centers its items: without this width, the text grows past the margins and gets clipped.
            instructionsLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            // Full width: the label wraps between the margins instead of being clipped.
            self.openSettingsButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.openSettingsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: VoiceOverAlertViewController.minimumTouchTarget)
        ])
    }
    
    /// The logo is decoration: it is hidden when the text and the button need the whole screen (small iPhones, large text sizes).
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first,
              let stackView = voiceOverActivationInstructionsView,
              let logo = stackView.arrangedSubviews.last as? UIImageView else { return }
        // Measured on the laid-out content, once the logo is shown: hide it only when the content overflows the screen.
        if !logo.isHidden && scrollView.contentSize.height > scrollView.bounds.height {
            logo.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    @IBAction func onContinueButtonTouched() {
        coordinator?.dismissActivateVoiceOverAlert()
    }

    @objc private func onOpenSettingsButtonTouched() {
        VoiceOverAlertViewController.logger.info("Open Settings button touched")
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            VoiceOverAlertViewController.logger.error("Invalid Settings URL: \(UIApplication.openSettingsURLString, privacy: .public)")
            showOpenSettingsError()
            return
        }
        UIApplication.shared.open(settingsURL) { [weak self] success in
            guard !success else { return }
            VoiceOverAlertViewController.logger.error("Failed to open Settings from VoiceOver activation, url: \(settingsURL.absoluteString, privacy: .public)")
            self?.showOpenSettingsError()
        }
    }

    private func showOpenSettingsError() {
        let alert = UIAlertController(title: nil, message: L10n.voOpenSettingsError, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.ok, style: .default))
        self.present(alert, animated: true)
    }
    
    @objc internal func voiceOverStatusChanged() {
        let isVoiceOverRunning = EscapeFromBlindnessAccessibility.shared.isVoiceOverRunning
        
        if isVoiceOverRunning {
            EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.voiceOverOnSuccessMessageLabel)
            self.voiceOverActivationInstructionsView.isHidden = true
            self.userCanContinueInstructionsView.isHidden = false
        } else {
            self.voiceOverActivationInstructionsView.isHidden = false
            self.userCanContinueInstructionsView.isHidden = true
        }
    }

}
