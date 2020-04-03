//
//  PollWidgetTheme.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/15/19.
//

import UIKit

/// Customizable properties of the Poll Widget
@objc public class PollWidgetTheme: NSObject, ChoiceWidgetTheme {
    /// Changes the gradient left color
    public var titleGradientLeft: UIColor
    /// Changes the gradien right color
    public var titleGradientRight: UIColor
    /// Changes the user's selection colors
    public var selectedColors: ChoiceWidgetOptionColors
    ///
    public init(titleGradientLeft: UIColor, titleGradientRight: UIColor, selectedColors: ChoiceWidgetOptionColors) {
        self.titleGradientLeft = titleGradientLeft
        self.titleGradientRight = titleGradientRight
        self.selectedColors = selectedColors
    }
}
