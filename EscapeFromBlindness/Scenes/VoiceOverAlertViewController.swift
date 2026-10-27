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
    private static let minimumTouchTarget: CGFloat = 44
    private static let instructionsMaximumPointSize: CGFloat = 34
    private static let buttonMaximumPointSize: CGFloat = 28
    private static let instructionsIdentifier = "activationVoiceOver.consignes"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Reglages")

    /// Seul bouton de l'écran d'activation : ouvre l'app Réglages, où l'utilisateur active VoiceOver.
    let openSettingsButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = L10n.voOpenSettings
        // Blanc sur le fond noir de l'écran, texte noir : contraste maximal, en mode clair comme en sombre.
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = .black
        configuration.titleLineBreakMode = .byWordWrapping
        // Plafonné sous la taille du texte explicatif : le texte reste le plus grand de l'écran.
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
        setupOpenSettingsButton()
    }

    /// Place « Ouvrir les Réglages » sous le texte explicatif. Les consignes défilent : en très grande taille de texte,
    /// le bouton reste atteignable au lieu de sortir de l'écran.
    private func setupOpenSettingsButton() {
        let instructionsLabel = self.voiceOverActivationInstructionsLabel!
        instructionsLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: instructionsLabel.font, maximumPointSize: VoiceOverAlertViewController.instructionsMaximumPointSize)
        instructionsLabel.adjustsFontForContentSizeCategory = true
        instructionsLabel.accessibilityIdentifier = VoiceOverAlertViewController.instructionsIdentifier

        let stackView = self.voiceOverActivationInstructionsView!
        stackView.insertArrangedSubview(self.openSettingsButton, at: stackView.arrangedSubviews.firstIndex(of: instructionsLabel)! + 1)
        stackView.spacing = VoiceOverAlertViewController.blockSpacing
        self.openSettingsButton.addTarget(self, action: #selector(onOpenSettingsButtonTouched), for: .touchUpInside)

        // Retirer la pile de la vue efface ses contraintes du xib : texte, bouton et icône défilent, alignés en haut.
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.removeFromSuperview()
        scrollView.addSubview(stackView)
        self.view.insertSubview(scrollView, at: 0)

        let safeArea = self.view.safeAreaLayoutGuide
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: VoiceOverAlertViewController.sideMargin),
            stackView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -VoiceOverAlertViewController.sideMargin),
            stackView.topAnchor.constraint(equalTo: content.topAnchor, constant: VoiceOverAlertViewController.topMargin),
            stackView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -VoiceOverAlertViewController.bottomMargin),
            // La pile centre ses éléments : sans cette largeur, le texte s'élargit au-delà des marges et se fait couper.
            instructionsLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            // Pleine largeur : le libellé passe à la ligne entre les marges au lieu d'être coupé.
            self.openSettingsButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.openSettingsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: VoiceOverAlertViewController.minimumTouchTarget)
        ])
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
