//
//  CGFloat+Add.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-16.
//

import UIKit

extension CGFloat {
    static func add(_ x: CGFloat?, _ y: CGFloat?) -> CGFloat {
        return (x ?? CGFloat(0)) + (y ?? CGFloat(0))
    }
}
