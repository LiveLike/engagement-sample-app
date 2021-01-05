//
//  Theme+Deprecations.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/1/20.
//

import Foundation

//
//  PollWidgetTheme.swift
//  LiveLikeSDK
//
//  Created by jelzon on 3/15/19.
//

import UIKit

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

/// Customizable properties of the Poll Widget
@objc public class PollWidgetTheme: NSObject {
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

/// Customizable properties of the Prediction Widget
public struct PredictionWidgetTheme {
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

/// Customizable properties of the Quiz Widget
@objc public class QuizWidgetTheme: NSObject {
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

/// Customizable properties of the Alert Widget
@objc public class AlertWidgetTheme: NSObject {
    /// Changes the gradient left color
    public var titleGradientLeft: UIColor
    /// Changes the gradient right color
    public var titleGradientRight: UIColor
    /// Changes the background color of the link area
    public var linkBackgroundColor: UIColor

    ///
    public init(titleGradientLeft: UIColor, titleGradientRight: UIColor, linkBackgroundColor: UIColor) {
        self.titleGradientLeft = titleGradientLeft
        self.titleGradientRight = titleGradientRight
        self.linkBackgroundColor = linkBackgroundColor
    }
}
