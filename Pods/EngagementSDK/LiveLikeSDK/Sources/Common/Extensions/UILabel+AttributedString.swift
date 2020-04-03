//
//  UILabel+AttributedString.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-05-07.
//

import UIKit

extension UILabel {
    func setWidgetText(_ text: String,
                       for theme: Theme,
                       category: Theme.TextCategory,
                       alignment: NSTextAlignment = .natural) {
        switch category {
        case .primary:
            setWidgetPrimaryText(text, theme: theme, alignment: alignment)
        case .secondary:
            setWidgetSecondaryText(text, theme: theme, alignment: alignment)
        case .tertiary:
            setWidgetTertiaryText(text, theme: theme, alignment: alignment)
        }
    }

    func setWidgetPrimaryText(_ text: String, theme: Theme, alignment: NSTextAlignment = .left) {
        attributedText = NSMutableAttributedString(text, font: theme.fontPrimary, color: theme.widgetFontPrimaryColor, lineSpacing: theme.widgetFontPrimaryLineSpacing, alignment: alignment)
    }

    func setWidgetSecondaryText(_ text: String, theme: Theme, alignment: NSTextAlignment = .left) {
        attributedText = NSMutableAttributedString(text, font: theme.fontSecondary, color: theme.widgetFontSecondaryColor, lineSpacing: theme.widgetFontSecondaryLineSpacing, alignment: alignment)
    }

    func setWidgetTertiaryText(_ text: String, theme: Theme, alignment: NSTextAlignment = .left) {
        attributedText = NSMutableAttributedString(text, font: theme.fontTertiary, color: theme.widgetFontTertiaryColor, lineSpacing: theme.widgetFontTertiaryLineSpacing, alignment: alignment)
    }
}

extension NSMutableAttributedString {
    convenience init(_ text: String, font: UIFont, color: UIColor, lineSpacing: CGFloat, alignment: NSTextAlignment = .left) {
        let attributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: color
        ]
        self.init(string: text, attributes: attributes)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        if lineSpacing > 0 {
            paragraphStyle.lineSpacing = lineSpacing
        }
        addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: length))
    }
}

extension Theme {
    enum TextCategory {
        case primary
        case secondary
        case tertiary
    }
}
