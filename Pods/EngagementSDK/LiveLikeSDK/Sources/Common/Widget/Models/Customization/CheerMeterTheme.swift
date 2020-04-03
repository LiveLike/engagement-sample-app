//
//  CheerMeterTheme.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/28/19.
//

import UIKit

@objc public class CheerMeterTheme: NSObject {
    /// Changes the font of your score and game start countdown timer
    @objc public var scoreAndCountdownFont: UIFont
    /// Changes the text color of your score and game start countdown timer
    @objc public var scoreAndCountdownTextColor: UIColor
    /// Changes the background color of the title
    @objc public var titleBackgroundColor: UIColor
    /// Changes the background color of the tutorial part of the Cheer Meter
    @objc public var tutorialBackgroundColor: UIColor
    /// Changes the margins of the title
    @objc public var titleMargins: UIEdgeInsets

    /// Changes the left color of the left team bar
    @objc public var teamOneLeftColor: UIColor
    /// Changes the right color of the left team bar
    @objc public var teamOneRightColor: UIColor
    /// Changes the font of the left team bar label
    @objc public var teamOneFont: UIFont
    /// Changes the text color of the left team bar label
    @objc public var teamOneTextColor: UIColor

    /// Changes the left color of the right team bar
    @objc public var teamTwoLeftColor: UIColor
    /// Changes the right color of the right team bar
    @objc public var teamTwoRightColor: UIColor
    /// Changes the font of the right team bar label
    @objc public var teamTwoFont: UIFont
    /// Changes the text color of the right team bar label
    @objc public var teamTwoTextColor: UIColor

    /// Defaults
    public override init() {
        scoreAndCountdownFont = UIFont.systemFont(ofSize: 32, weight: .bold)
        scoreAndCountdownTextColor = .white
        titleBackgroundColor = UIColor(white: 0, alpha: 0.8)
        tutorialBackgroundColor = UIColor(white: 0, alpha: 0.8)
        titleMargins = UIEdgeInsets(top: 10, left: 10, bottom: -10, right: -10)

        teamOneLeftColor = UIColor(red: 80, green: 160, blue: 250)
        teamOneRightColor = UIColor(red: 40, green: 40, blue: 180)
        teamOneTextColor = .white
        teamOneFont = UIFont.systemFont(ofSize: 14)

        teamTwoLeftColor = UIColor(red: 160, green: 0, blue: 40)
        teamTwoRightColor = UIColor(red: 250, green: 80, blue: 100)
        teamTwoTextColor = .white
        teamTwoFont = UIFont.systemFont(ofSize: 14)
    }
}
