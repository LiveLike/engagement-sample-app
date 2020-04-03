//
//  AlertWidgetTheme.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

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
