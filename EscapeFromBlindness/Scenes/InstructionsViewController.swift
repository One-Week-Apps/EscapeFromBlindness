//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit
import os

extension InstructionsViewController: XibLoadable {}

class InstructionsViewController: UIViewController, Coordinated {
    var coordinator: AppCoordinatorProtocol?

    enum Scenario {
        case intro
        case gameEnd
    }
    var scenario: Scenario!

    var interactor: InstructionsInteractorProtocol? = InstructionsInteractor()
    private var instructions: [String] = []
    private var currentInstructionIndex = 0
    private var currentInstruction: String? {
        return self.instructions[safe: self.currentInstructionIndex]
    }

    @IBOutlet weak var instructionsLabel: UILabel!

    var timer: Timer?
    /// Animations de consigne en cours, et défilement terminé : « Rejouer » n'apparaît qu'une fois la dernière consigne posée.
    private var latestRequestedInstructionIndex = 0
    private var pendingInstructionUpdates = 0
    private var hasRunOutOfInstructions = false

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FinDeJeu")
    private static let eyebrowIdentifier = "finDeJeu.libelle"
    private static let titleIdentifier = "finDeJeu.titre"
    /// Posé sur la consigne de fin une fois qu'elle est affichée : permet aux tests d'attendre la fin du défilement.
    private static let lastInstructionIdentifier = "finDeJeu.derniereConsigne"
    private static let sideMargin: CGFloat = 24
    private static let topMargin: CGFloat = 32
    private static let bottomMargin: CGFloat = 24
    private static let blockSpacing: CGFloat = 24
    /// Le libellé et le titre forment un seul bloc : 8 pt entre les deux (grille de 8 pt).
    private static let eyebrowSpacing: CGFloat = 8
    /// Marge entre le bouton « Rejouer » et le bas de la zone sûre, et entre le défilement et le bouton.
    private static let buttonBottomInset: CGFloat = 16
    private static let minimumTouchTarget: CGFloat = 44
    // Le titre reste le plus grand texte de l'écran, à toutes les tailles de texte.
    private static let titleMaximumPointSize: CGFloat = 40
    private static let eyebrowMaximumPointSize: CGFloat = 22
    private static let bodyMaximumPointSize: CGFloat = 24
    private static let buttonMaximumPointSize: CGFloat = 22
    /// Blanc à 75 % : libellé discret, distinct du titre en blanc plein.
    private static let eyebrowColor = UIColor(white: 1, alpha: 0.75)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.enlargeTextForIPad()
        // The text grows with Dynamic Type: its height comes from its content, and its width from the readable area.
        instructionsLabel.constraints.filter { $0.firstAttribute == .height }.forEach { $0.isActive = false }
        instructionsLabel.widthAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.widthAnchor).isActive = true
        if scenario == .gameEnd {
            configureGameEndLayout()
        }
        self.replayButton.setTitle(L10n.replay, for: .normal)
        self.replayButton.accessibilityHint = L10n.replayHint
        self.replayButton.accessibilityIdentifier = "instructions.replayButton"

        guard let instructions = scenario == .intro ? interactor?.fetchIntroInstructions() : interactor?.fetchGameEndInstructions() else {
            if scenario == .gameEnd {
                InstructionsViewController.logger.error("Consignes de fin de jeu introuvables : aucun texte n'est affiché")
            }
            return
        }

        self.instructions = instructions
        if let firstInstruction = instructions.first {
            self.instructionsLabel.text = firstInstruction
        }
        if scenario == .gameEnd {
            InstructionsViewController.logger.info("Écran de fin de jeu affiché, \(instructions.count, privacy: .public) consignes")
        }

        EscapeFromBlindnessAccessibility.shared.post(
            notification: .layoutChanged,
            argument: self.instructionsLabel
        )

        startInstructionsUpdateTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.instructionsLabel)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopInstructionsUpdateTimer()
    }

    private func startInstructionsUpdateTimer() {
        let interval = interactor?.instructionInterval ?? InstructionsInteractor.productionInstructionInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let strongSelf = self else { return }

            strongSelf.currentInstructionIndex += 1
            strongSelf.handleInstruction(strongSelf.currentInstruction)
        }
        timer?.fire()
    }

    private func stopInstructionsUpdateTimer() {
        timer?.invalidate()
    }

    private func handleInstruction(_ nextInstruction: String?) {
        if let nextInstruction = nextInstruction {
            setInstructionsText(nextInstruction, index: currentInstructionIndex)
        } else {
            timer?.invalidate()
            if self.scenario == .intro {
                coordinator?.validateChapter()
            } else {
                hasRunOutOfInstructions = true
                revealReplayButtonIfReady()
            }
        }
    }

    /// Affiche « Rejouer » une fois le défilement terminé et la dernière consigne posée (la transition dure 0,5 s).
    private func revealReplayButtonIfReady() {
        guard hasRunOutOfInstructions, pendingInstructionUpdates == 0, replayButton.isHidden else { return }
        replayButton.isHidden = false
        EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: replayButton)
    }

    @IBOutlet weak var replayButton: UIButton!
    @IBAction func onReplayButtonTouched(_ sender: Any) {
        if scenario == .gameEnd {
            InstructionsViewController.logger.info("Bouton Rejouer touché")
        }
        coordinator?.replay()
    }

    private func setInstructionsText(_ text: String, index: Int) {
        let duration = interactor?.transitionDuration ?? 0.5
        pendingInstructionUpdates += 1
        latestRequestedInstructionIndex = index
        UIView.animate(withDuration: duration, animations: {
            self.instructionsLabel.alpha = 0
        }, completion: { _ in
            // Fades can finish out of order when the timer fires late: an older instruction never overwrites a newer one.
            guard index == self.latestRequestedInstructionIndex else {
                self.pendingInstructionUpdates -= 1
                self.revealReplayButtonIfReady()
                return
            }
            self.instructionsLabel.text = text
            UIView.animate(withDuration: duration) {
                self.instructionsLabel.alpha = 1
            }
            EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.instructionsLabel)
            if self.scenario == .gameEnd {
                let isLastInstruction = index == self.instructions.count - 1
                self.instructionsLabel.accessibilityIdentifier = isLastInstruction ? InstructionsViewController.lastInstructionIdentifier : nil
                InstructionsViewController.logger.debug("Consigne de fin de jeu affichée : \(index + 1, privacy: .public) sur \(self.instructions.count, privacy: .public)")
            }
            self.pendingInstructionUpdates -= 1
            self.revealReplayButtonIfReady()
        })

    }

    // MARK: - Fin de jeu

    /// Écran de fin : libellé et titre en haut, consignes qui défilent dans la zone du milieu, « Rejouer » ancré en bas.
    /// Le défilement s'arrête au-dessus du bouton : en très grande taille de texte, rien ne passe derrière lui.
    /// L'écran d'introduction garde sa mise en page.
    private func configureGameEndLayout() {
        guard let stackView = instructionsLabel.superview as? UIStackView else {
            InstructionsViewController.logger.error("Pile des consignes de fin de jeu introuvable : mise en page d'origine conservée")
            return
        }

        let eyebrowLabel = UILabel()
        eyebrowLabel.text = L10n.gameEndEyebrow
        eyebrowLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(
            for: .custom(style: .montserratSemiBold, size: 15),
            maximumPointSize: InstructionsViewController.eyebrowMaximumPointSize
        )
        eyebrowLabel.textColor = InstructionsViewController.eyebrowColor
        eyebrowLabel.numberOfLines = 0
        eyebrowLabel.adjustsFontForContentSizeCategory = true
        eyebrowLabel.accessibilityIdentifier = InstructionsViewController.eyebrowIdentifier

        let titleLabel = UILabel()
        titleLabel.text = interactor?.fetchGameEndTitle() ?? ""
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .custom(style: .montserratExtraBold, size: 34),
            maximumPointSize: InstructionsViewController.titleMaximumPointSize
        )
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityIdentifier = InstructionsViewController.titleIdentifier
        titleLabel.accessibilityTraits = .header

        instructionsLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 18),
            maximumPointSize: InstructionsViewController.bodyMaximumPointSize
        )
        instructionsLabel.adjustsFontForContentSizeCategory = true
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .natural
        // La hauteur fixe de 200 pt est retirée : le texte passe à la ligne au lieu d'être coupé.
        instructionsLabel.constraints.filter { $0.firstAttribute == .height }.forEach { $0.isActive = false }

        stackView.alignment = .fill
        stackView.spacing = InstructionsViewController.blockSpacing
        let titleIndex = stackView.arrangedSubviews.firstIndex(of: instructionsLabel) ?? 0
        stackView.insertArrangedSubview(titleLabel, at: titleIndex)
        stackView.insertArrangedSubview(eyebrowLabel, at: titleIndex)
        stackView.setCustomSpacing(InstructionsViewController.eyebrowSpacing, after: eyebrowLabel)

        // Le bouton du xib (caché, dans la pile) est remplacé par le bouton plein des autres écrans, ancré en bas.
        let previousReplayButton = self.replayButton!
        previousReplayButton.removeFromSuperview()
        let newReplayButton = makeReplayButton()
        self.view.addSubview(newReplayButton)
        self.replayButton = newReplayButton

        // Retirer la pile de la vue efface ses contraintes du xib : tout le texte défile, aligné en haut.
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.removeFromSuperview()
        scrollView.addSubview(stackView)
        self.view.insertSubview(scrollView, at: 0)

        let safeArea = self.view.safeAreaLayoutGuide
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        let buttonInset = InstructionsViewController.buttonBottomInset
        NSLayoutConstraint.activate([
            newReplayButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: InstructionsViewController.sideMargin),
            newReplayButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -InstructionsViewController.sideMargin),
            newReplayButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -buttonInset),

            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: newReplayButton.topAnchor, constant: -buttonInset),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),

            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: InstructionsViewController.sideMargin),
            stackView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -InstructionsViewController.sideMargin),
            stackView.topAnchor.constraint(equalTo: content.topAnchor, constant: InstructionsViewController.topMargin),
            stackView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -InstructionsViewController.bottomMargin)
        ])
    }

    /// Bouton « Rejouer » : plein, blanc sur fond noir comme « Ouvrir les Réglages », texte plafonné sous le titre.
    private func makeReplayButton() -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = L10n.replay
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = .black
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFontMetrics(forTextStyle: .headline).scaledFont(
                for: .custom(style: .montserratExtraBold, size: 17),
                maximumPointSize: InstructionsViewController.buttonMaximumPointSize
            )
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.setTitle(L10n.replay, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: InstructionsViewController.minimumTouchTarget).isActive = true
        button.addTarget(self, action: #selector(onReplayButtonTouched(_:)), for: .touchUpInside)
        return button
    }

}
