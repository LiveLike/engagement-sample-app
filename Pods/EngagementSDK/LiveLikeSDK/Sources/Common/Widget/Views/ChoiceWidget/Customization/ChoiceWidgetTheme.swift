//
//  ChoiceWidgetTheme.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/21/19.
//

import UIKit

protocol ChoiceWidgetTheme {
    var titleGradientLeft: UIColor { get }
    var titleGradientRight: UIColor { get }
}

/// Customizable properties of a Poll, Quiz, or Prediction Widget option
@objc public class ChoiceWidgetOptionColors: NSObject {
    /// Changes the border color of the option
    public var borderColor: UIColor
    /// Changes the progress bar gradient left color
    public var barGradientLeft: UIColor
    /// Changes the progress bar gradient right color
    public var barGradientRight: UIColor

    init(borderColor: UIColor, barGradientLeft: UIColor, barGradientRight: UIColor) {
        self.borderColor = borderColor
        self.barGradientLeft = barGradientLeft
        self.barGradientRight = barGradientRight
    }
}
