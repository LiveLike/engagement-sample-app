//
//  UICoordinateSpace+Intersection.swift
//  EngagementSDK
//

import UIKit

extension UICoordinateSpace {
    func intersection(_ otherSpace: UICoordinateSpace) -> CGRect? {
        let otherSpaceRectInOurSpace = convert(otherSpace.bounds, from: otherSpace)
        let result = bounds.intersection(otherSpaceRectInOurSpace)
        return !result.isNull ? result : nil
    }
}
