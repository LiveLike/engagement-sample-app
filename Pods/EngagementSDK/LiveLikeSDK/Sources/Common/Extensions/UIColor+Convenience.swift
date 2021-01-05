//
//  UIColor+Convenience.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-10.
//

import UIKit

extension UIColor {
    convenience init(rInt: Int, gInt: Int, bInt: Int, alpha: CGFloat = 1.0) {
        let newRed = CGFloat(rInt) / 255

        let newGreen = CGFloat(gInt) / 255

        let newBlue = CGFloat(bInt) / 255

        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
    }
}
