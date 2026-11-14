//
//  Created by Michael Martinez on 21/04/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit

class LoadLevelCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var levelLockedImageView: UIImageView!
    
    private static let completedColor = UIColor(red: 80/255, green: 144/255, blue: 6/255, alpha: 1)
    private static let lockedColor = UIColor(white: 0.18, alpha: 1)
    private static let levelIdentifierPrefix = "levelSelection.level."
    private static let tileIdentifierPrefix = "tuileNiveau_"

    /// The number follows Dynamic Type and never shrinks: the grid enlarges the tiles so that it fits.
    static func levelFont(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: .custom(style: .montserratExtraBold, size: 35), compatibleWith: traitCollection)
    }

    enum State {
        case completed
        case unlocked
        case locked
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView.layer.cornerRadius = 10
        self.containerView.backgroundColor = .clear
        self.levelLabel.textColor = .black
        self.levelLabel.font = LoadLevelCollectionViewCell.levelFont()
        self.levelLabel.adjustsFontForContentSizeCategory = true
        self.levelLabel.adjustsFontSizeToFitWidth = false
        self.levelLabel.numberOfLines = 0
        self.levelLabel.lineBreakMode = .byWordWrapping
        self.levelLockedImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.levelLockedImageView.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
            self.levelLockedImageView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor),
            self.levelLockedImageView.widthAnchor.constraint(equalTo: self.containerView.widthAnchor, multiplier: 0.6),
            self.levelLockedImageView.heightAnchor.constraint(equalTo: self.containerView.heightAnchor, multiplier: 0.6)
        ])
    }
    
    func configure(chapterIndex: Int, levelIndex: Int, state: State) {
        let displayedChapterIndex = chapterIndex + 1
        let displayedLevelIndex = levelIndex + 1
        self.levelLabel.accessibilityIdentifier = "\(LoadLevelCollectionViewCell.levelIdentifierPrefix)\(displayedChapterIndex).\(displayedLevelIndex)"
        // The whole tile (cell): the level number alone repeats across chapters, hence the chapter first.
        self.accessibilityIdentifier = "\(LoadLevelCollectionViewCell.tileIdentifierPrefix)\(displayedChapterIndex)_\(displayedLevelIndex)"

        switch state {
        case .completed:
            self.levelLabel.text = "\(displayedLevelIndex)"
            self.levelLabel.accessibilityLabel = "\(L10n.level) \(displayedLevelIndex) (\(L10n.complete))"
            self.levelLabel.accessibilityTraits = .button

            self.containerView.backgroundColor = LoadLevelCollectionViewCell.completedColor
            self.levelLockedImageView.isHidden = true
        case .unlocked:
            self.levelLabel.text = "\(displayedLevelIndex)"
            self.levelLabel.accessibilityLabel = "\(L10n.continue) \(L10n.level) \(displayedLevelIndex) \(L10n.chapter) \(displayedChapterIndex)"
            self.levelLabel.accessibilityTraits = .button

            self.containerView.backgroundColor = .white
            self.levelLockedImageView.isHidden = true
        case .locked:
            self.levelLabel.text = " "
            // Tapping a locked level does nothing: VoiceOver reads it as text, name then state.
            self.levelLabel.accessibilityLabel = L10n.levelLockedAccessibility(displayedLevelIndex)
            self.levelLabel.accessibilityTraits = .staticText

            self.containerView.backgroundColor = LoadLevelCollectionViewCell.lockedColor
            self.levelLockedImageView.isHidden = false
        }
    }

}
