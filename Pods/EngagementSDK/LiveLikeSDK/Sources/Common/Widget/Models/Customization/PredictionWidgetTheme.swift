//
//  PredictionWidgetTheme.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/17/19.
//

import UIKit

/// Customizable properties of the Prediction Widget
public struct PredictionWidgetTheme: ChoiceWidgetTheme {
    /// Changes the gradient left color
    public var titleGradientLeft: UIColor
    /// Changes the gradient right color
    public var titleGradientRight: UIColor
    /// Changes the user's selection border color
    public var optionSelectBorderColor: UIColor
    /// Changes the color of the option results gradient
    public var optionGradientColors: ChoiceWidgetOptionColors
    /// Changes the lottie animation that plays when the prediction widget timer completes
    public var lottieAnimationOnTimerCompleteFilepaths: [String]
    
    ///
    public init(
        titleGradientLeft: UIColor,
        titleGradientRight: UIColor,
        optionSelectBorderColor: UIColor,
        optionGradientColors: ChoiceWidgetOptionColors,
        lottieAnimationOnTimerCompleteFilepath: [String]
    ) {
        self.titleGradientLeft = titleGradientLeft
        self.titleGradientRight = titleGradientRight
        self.optionSelectBorderColor = optionSelectBorderColor
        self.optionGradientColors = optionGradientColors
        self.lottieAnimationOnTimerCompleteFilepaths = lottieAnimationOnTimerCompleteFilepath
    }
}
