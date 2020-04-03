//
//  ClosedRange+Bound.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-10.
//

import Foundation

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        return lowerBound > value ? lowerBound
            : upperBound < value ? upperBound
            : value
    }
}
