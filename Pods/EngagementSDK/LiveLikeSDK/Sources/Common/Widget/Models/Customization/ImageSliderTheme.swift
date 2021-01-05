//
//  ImageSliderTheme.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/20/19.
//

import UIKit

@objc public class ImageSliderTheme: NSObject {
    /// Changes the title background color
    public var titleBackgroundColor: UIColor
    /// Changes the track gradient left color
    public var trackGradientLeft: UIColor
    /// Changes the track gradient right color
    public var trackGradientRight: UIColor
    /// Changes the track minimum tint color
    public var trackMinimumTint: UIColor
    /// Changes the track maximum tint color
    public var trackMaximumTint: UIColor
    /// Changes the results hot color
    public var resultsHotColor: UIColor
    /// Changes the results cold color
    public var resultsColdColor: UIColor
    /// Changes the margins of the title
    public var titleMargins: UIEdgeInsets

    /// Defaults
    public override init() {
        titleBackgroundColor = UIColor(rInt: 0, gInt: 0, bInt: 0, alpha: 0.8)
        trackGradientLeft = UIColor(rInt: 255, gInt: 240, bInt: 0)
        trackGradientRight = UIColor(rInt: 160, gInt: 255, bInt: 40)
        trackMinimumTint = .clear
        trackMaximumTint = .white
        resultsHotColor = UIColor(rInt: 255, gInt: 5, bInt: 45)
        resultsColdColor = UIColor(rInt: 60, gInt: 30, bInt: 255)
        titleMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: -2)
    }
}
