//
//  UIFont+Accessibility.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 12/20/19.
//

import UIKit

extension UIFont {
    func livelike_bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        return UIFont(descriptor: descriptor!, size: 0)
    }

    /// Set a limit to how large the font is allowed to grow
    /// - Parameter size: size limit
    func maxAccessibilityFontSize(size: CGFloat) -> UIFont {
        guard let styleName = fontDescriptor.fontAttributes[.textStyle] as? String else {
            return self
        }
        
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: TextStyle(rawValue: styleName))
        let maxFont = UIFont(descriptor: fontDescriptor, size: size)
        
        return fontDescriptor.pointSize <= size ? self : maxFont
    }
}
