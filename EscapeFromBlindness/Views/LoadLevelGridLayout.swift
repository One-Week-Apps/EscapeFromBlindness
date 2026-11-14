//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import UIKit

/// Regular level grid: all tiles have the same size, spacing stays `minimumInteritemSpacing`
/// and each tile snaps to its column. Otherwise the flow layout spreads the leftover space of an incomplete row
/// and the last row stretches or centers.
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
        // Same computation as the flow layout to fill a row: same-size tiles, minimum spacing.
        let columns = max(1, Int((width + minimumInteritemSpacing) / step))
        let column = attributes.indexPath.item % columns
        copy.frame.origin.x = sectionInset.left + CGFloat(column) * step
        return copy
    }
}
