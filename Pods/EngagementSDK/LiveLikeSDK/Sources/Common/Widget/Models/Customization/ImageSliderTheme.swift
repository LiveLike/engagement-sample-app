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
        titleBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        trackGradientLeft = UIColor(red: 255, green: 240, blue: 0)
        trackGradientRight = UIColor(red: 160, green: 255, blue: 40)
        trackMinimumTint = .clear
        trackMaximumTint = .white
        resultsHotColor = UIColor(red: 255, green: 5, blue: 45)
        resultsColdColor = UIColor(red: 60, green: 30, blue: 255)
        titleMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: -2)
    }
}
