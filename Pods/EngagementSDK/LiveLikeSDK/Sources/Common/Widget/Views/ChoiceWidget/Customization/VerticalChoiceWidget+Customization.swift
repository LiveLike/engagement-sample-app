//
//  VerticalChoiceWidget+Customization.swift
//  EngagementSDK
//
//  Created by jelzon on 3/21/19.
//

import UIKit

extension VerticalChoiceWidget {
    func customize(_ customization: ChoiceWidgetTheme, theme: Theme) {
        clipsToBounds = true
        layer.cornerRadius = theme.widgetCornerRadius
        stackView.spacing = theme.interOptionSpacing
        coreWidgetView.stackView.spacing = theme.titleBodySpacing
        coreWidgetView.baseView.layer.cornerRadius = theme.widgetCornerRadius
        contentBackgroundColor = theme.widgetBodyColor
        titleView.customizeTitle(font: theme.fontSecondary, textColor: theme.widgetFontSecondaryColor, gradientStart: customization.titleGradientLeft, gradientEnd: customization.titleGradientRight)
    }
}
