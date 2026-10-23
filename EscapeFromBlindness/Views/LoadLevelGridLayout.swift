//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit

/// Grille régulière des niveaux : toutes les tuiles ont la même taille, l'écart reste `minimumInteritemSpacing`
/// et chaque tuile se cale sur sa colonne. Sans cela, la flow layout répartit l'espace restant d'un rang incomplet
/// et le dernier rang s'étire ou se centre.
final class LoadLevelGridLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return super.layoutAttributesForElements(in: rect)?.map { attributes in
            attributes.representedElementCategory == .cell ? aligned(attributes) : attributes
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForItem(at: indexPath).map(aligned)
    }

    private func aligned(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView = collectionView,
              let copy = attributes.copy() as? UICollectionViewLayoutAttributes else { return attributes }
        let width = collectionView.bounds.width - sectionInset.left - sectionInset.right
        let step = copy.frame.width + minimumInteritemSpacing
        // Même calcul que la flow layout pour remplir un rang : tuiles de même taille, écart minimal.
        let columns = max(1, Int((width + minimumInteritemSpacing) / step))
        let column = attributes.indexPath.item % columns
        copy.frame.origin.x = sectionInset.left + CGFloat(column) * step
        return copy
    }
}
