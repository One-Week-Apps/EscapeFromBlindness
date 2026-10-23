//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit
import os

/// Réglages du jeu, en liste groupée native. La ligne « VoiceOver » ouvre l'app Réglages du système.
class SettingsViewController: UITableViewController, Coordinated {
    var coordinator: AppCoordinatorProtocol?

    static let voiceOverLinkIdentifier = "reglagesLienVoiceOver"
    private static let cellReuseId = "settingsCell"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Reglages")

    /// Ouverture d'URL injectable pour les tests ; par défaut, celle de l'application.
    var openURL: (URL, @escaping (Bool) -> Void) -> Void = { url, completion in
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Le jeu se joue sur fond noir : la liste garde l'apparence sombre native, lisible quel que soit le mode du système.
        self.overrideUserInterfaceStyle = .dark
        self.title = L10n.settings
        self.tableView.register(SettingsVoiceOverCell.self, forCellReuseIdentifier: SettingsViewController.cellReuseId)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            // Retour à la sélection des niveaux, qui s'affiche sans barre de navigation.
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return L10n.settingsVoiceoverFooter
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsViewController.cellReuseId, for: indexPath) as! SettingsVoiceOverCell
        cell.button.removeTarget(nil, action: nil, for: .touchUpInside)
        cell.button.addTarget(self, action: #selector(openVoiceOverSettings), for: .touchUpInside)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openVoiceOverSettings()
    }

    // MARK: - Actions

    /// iOS n'offre pas d'URL publique vers Accessibilité > VoiceOver : on ouvre l'app Réglages, et le pied de section guide la suite.
    @objc func openVoiceOverSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            SettingsViewController.logger.error("Cannot build settings URL from \(UIApplication.openSettingsURLString, privacy: .public)")
            showOpenFailure()
            return
        }
        SettingsViewController.logger.info("Opening system settings for VoiceOver")
        openURL(url) { [weak self] success in
            guard !success else { return }
            SettingsViewController.logger.error("System refused to open settings URL \(url.absoluteString, privacy: .public)")
            self?.showOpenFailure()
        }
    }

    private func showOpenFailure() {
        let alert = UIAlertController(title: nil, message: L10n.settingsOpenError, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.ok, style: .default))
        present(alert, animated: true)
    }
}

/// Ligne « VoiceOver » au style des Réglages : libellé à gauche, chevron à droite.
/// Le bouton qui remplit la ligne porte le rôle et l'indice lus par VoiceOver ; la cellule n'est qu'un conteneur.
final class SettingsVoiceOverCell: UITableViewCell {
    let button = UIButton(type: .custom)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
        self.isAccessibilityElement = false

        var configuration = UIButton.Configuration.plain()
        configuration.title = L10n.settingsVoiceover
        configuration.baseForegroundColor = .label
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .body)
            return outgoing
        }
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.accessibilityLabel = L10n.settingsVoiceover
        button.accessibilityHint = L10n.settingsVoiceoverHint
        button.accessibilityIdentifier = SettingsViewController.voiceOverLinkIdentifier

        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: margins.topAnchor),
            button.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
