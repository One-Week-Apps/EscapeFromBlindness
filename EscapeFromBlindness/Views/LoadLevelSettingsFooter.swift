//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit

/// Pied de la grille des niveaux : le bouton qui mène aux Réglages du jeu.
class LoadLevelSettingsFooter: UICollectionReusableView {
    static let topSpacing: CGFloat = 16
    static let verticalPadding: CGFloat = 8
    static let minimumTouchTarget: CGFloat = 44

    let button = UIButton(type: .custom)
    var onTap: (() -> Void)?

    static func font(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: .custom(style: .montserratSemiBold, size: 17), compatibleWith: traitCollection)
    }

    /// La hauteur suit la taille de texte (le libellé peut passer à la ligne), sans descendre sous la cible tactile minimale.
    static func height(width: CGFloat, traitCollection: UITraitCollection) -> CGFloat {
        let sizing = LoadLevelSettingsFooter(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        var fitted = CGSize.zero
        traitCollection.performAsCurrent {
            fitted = sizing.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                           withHorizontalFittingPriority: .required,
                                           verticalFittingPriority: .fittingSizeLevel)
        }
        return max(topSpacing + minimumTouchTarget, ceil(fitted.height))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        var configuration = UIButton.Configuration.plain()
        configuration.title = L10n.settings
        configuration.image = UIImage(systemName: "gearshape")
        configuration.imagePadding = LoadLevelSettingsFooter.verticalPadding
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .body)
        configuration.baseForegroundColor = .white
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.contentInsets = NSDirectionalEdgeInsets(top: LoadLevelSettingsFooter.verticalPadding, leading: 0,
                                                              bottom: LoadLevelSettingsFooter.verticalPadding, trailing: LoadLevelSettingsFooter.verticalPadding)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = LoadLevelSettingsFooter.font()
            return outgoing
        }
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.accessibilityIdentifier = "niveauxBoutonReglages"
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: LoadLevelSettingsFooter.topSpacing),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: LoadLevelSettingsFooter.minimumTouchTarget),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: LoadLevelSettingsFooter.minimumTouchTarget)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}
