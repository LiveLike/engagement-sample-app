//
//  UIColor+Convenience.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-10.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        let newRed = CGFloat(red) / 255

        let newGreen = CGFloat(green) / 255

        let newBlue = CGFloat(blue) / 255

        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
    }
}
