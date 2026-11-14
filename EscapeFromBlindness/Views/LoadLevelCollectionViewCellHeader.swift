//
//  Created by Michael Martinez on 21/04/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit

/// Two-level chapter header: small "Chapitre 1", then the chapter name.
class LoadLevelCollectionViewCellHeader: UICollectionReusableView {
    static let insets = UIEdgeInsets(top: 24, left: 0, bottom: 12, right: 0)
    /// Caps: at very large text sizes, the chapter name stays smaller than the screen title.
    static let nameMaximumPointSize: CGFloat = 40
    static let numberMaximumPointSize: CGFloat = 28
    static let numberColor = UIColor(white: 1, alpha: 0.75)
    /// Like the screen title: the dot of the "i" and the accents exceed the font's default line height.
    /// Applied to the chapter name only; the margin above the first line stays the one from `insets`.
    static let nameLineHeightMultiple: CGFloat = 1.2

    let titleLabel = UILabel()

    static func nameFont(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        return UIFontMetrics(forTextStyle: .title3).scaledFont(for: .custom(style: .montserratExtraBold, size: 20),
                                                               maximumPointSize: nameMaximumPointSize,
                                                               compatibleWith: traitCollection)
    }

    static func numberFont(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .custom(style: .montserratSemiBold, size: 15),
                                                                    maximumPointSize: numberMaximumPointSize,
                                                                    compatibleWith: traitCollection)
    }

    static func attributedTitle(number: String, name: String, traitCollection: UITraitCollection? = nil) -> NSAttributedString {
        let title = NSMutableAttributedString(string: number + "\n", attributes: [
            .font: numberFont(compatibleWith: traitCollection),
            .foregroundColor: numberColor
        ])
        let nameParagraph = NSMutableParagraphStyle()
        nameParagraph.lineHeightMultiple = nameLineHeightMultiple
        title.append(NSAttributedString(string: name, attributes: [
            .font: nameFont(compatibleWith: traitCollection),
            .foregroundColor: UIColor.white,
            .paragraphStyle: nameParagraph
        ]))
        return title
    }

    /// Height needed for a given title: the text wraps instead of shrinking.
    static func height(number: String, name: String, width: CGFloat, traitCollection: UITraitCollection) -> CGFloat {
        let bounds = attributedTitle(number: number, name: name, traitCollection: traitCollection).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return insets.top + ceil(bounds.height) + insets.bottom
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        addSubview(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(number: String, name: String, accessibilityLabel: String) {
        titleLabel.attributedText = LoadLevelCollectionViewCellHeader.attributedTitle(number: number, name: name, traitCollection: traitCollection)
        titleLabel.accessibilityLabel = accessibilityLabel
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds.inset(by: LoadLevelCollectionViewCellHeader.insets)
    }
}
