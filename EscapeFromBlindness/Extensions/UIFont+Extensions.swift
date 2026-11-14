//
//  Created by Stanislas Chevallier on 27/03/2019.
//  Copyright © 2019 Michael Martinez. All rights reserved.
//

import UIKit

extension UIFont {

    /// Usage: textLabel.font = UIFont.custom(style: .montserratSemiBold, size: 30)
    enum CustomFont: String {
        case lucioleRegular  = "Luciole-Regular"
        case lucioleBold     = "Luciole-Bold"
        case montserratBlack = "Montserrat-Black"
        case montserratBold  = "Montserrat-Bold"
        case montserratExtraBold  = "Montserrat-ExtraBold"
        case montserratSemiBold   = "Montserrat-SemiBold"
    }
    
    /// The sizes are written for iPhone. On iPad they grow with the screen, so text keeps its proportions.
    static let iPadSizeFactor: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.6 : 1

    static func custom(style: CustomFont, size: CGFloat) -> UIFont {
        return UIFont(name: style.rawValue, size: size * iPadSizeFactor)!
    }

    func scaled(using textStyle: UIFont.TextStyle) -> UIFont {
        let pointSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        let updatedFont = UIFont(name: fontName, size: pointSize)!
        return UIFontMetrics.default.scaledFont(for: updatedFont)
    }
}

extension UIView {
    /// Labels and buttons of this view tree, for the fonts set in Interface Builder:
    /// the size grows on iPad, and the text follows Dynamic Type on every device.
    /// Call once, in viewDidLoad.
    func enlargeTextForIPad() {
        let factor = UIFont.iPadSizeFactor
        if let label = self as? UILabel, let font = label.font {
            label.font = UIFontMetrics.default.scaledFont(for: font.withSize(font.pointSize * factor))
            label.adjustsFontForContentSizeCategory = true
        }
        if let button = self as? UIButton, let font = button.titleLabel?.font {
            button.titleLabel?.font = UIFontMetrics.default.scaledFont(for: font.withSize(font.pointSize * factor))
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        subviews.forEach { $0.enlargeTextForIPad() }
    }
}
