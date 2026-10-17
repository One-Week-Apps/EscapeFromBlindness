//
//  Created by Michael Martinez on 17/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit

/// Pied de la grille des niveaux : affiche la version sous la dernière case, dans le contenu qui défile.
class LoadLevelVersionFooter: UICollectionReusableView {
    /// Ajouté au `sectionInset.bottom` (20 pt) de la dernière section : 32 pt sous la dernière case.
    static let topSpacing: CGFloat = 12
    /// La grille s'arrête à la zone sûre : 8 pt au-dessus de la barre d'accueil.
    static let bottomSpacing: CGFloat = 8
    static let textStyle: UIFont.TextStyle = .footnote

    let versionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: LoadLevelVersionFooter.textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        // Le fond de l'accueil reste noir quel que soit le mode : on résout `secondaryLabel` dans sa variante sombre pour garder un contraste ≥ 4,5:1.
        label.overrideUserInterfaceStyle = .dark
        label.isUserInteractionEnabled = false
        label.accessibilityTraits = .staticText
        label.accessibilityIdentifier = "home.versionLabel"
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(versionLabel)
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            versionLabel.topAnchor.constraint(equalTo: topAnchor, constant: LoadLevelVersionFooter.topSpacing),
            versionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            versionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            versionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -LoadLevelVersionFooter.bottomSpacing)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, accessibilityText: String?) {
        versionLabel.text = text
        versionLabel.accessibilityLabel = accessibilityText
    }

    /// Hauteur du pied pour un texte donné, recalculée à chaque changement de taille de police.
    static func height(for text: String, width: CGFloat, traitCollection: UITraitCollection) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: traitCollection)
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return topSpacing + ceil(bounds.height) + bottomSpacing
    }
}
