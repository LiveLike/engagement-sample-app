//
//  PredictionWidgetTheme.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/17/19.
//

import UIKit

/// Customizable properties of the Prediction Widget
@objc public class PredictionWidgetTheme: NSObject, ChoiceWidgetTheme {
    /// Changes the gradient left color
    public var titleGradientLeft: UIColor
    /// Changes the gradient right color
    public var titleGradientRight: UIColor
    /// Changes the user's selection border color
    public var optionSelectBorderColor: UIColor
    ///
    public init(titleGradientLeft: UIColor, titleGradientRight: UIColor, optionSelectBorderColor: UIColor) {
        self.titleGradientLeft = titleGradientLeft
        self.titleGradientRight = titleGradientRight
        self.optionSelectBorderColor = optionSelectBorderColor
    }
}
