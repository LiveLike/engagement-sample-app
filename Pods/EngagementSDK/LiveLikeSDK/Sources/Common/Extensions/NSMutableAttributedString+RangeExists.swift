//
//  NSMutableAttributedString+RangeExists.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-12.
//

import UIKit

extension NSMutableAttributedString {
    // https://stackoverflow.com/questions/34190233/is-there-an-easy-method-to-check-is-an-nsrange-passed-to-substringwithrange-on-n
    func rangeExists(_ range: NSRange) -> Bool {
        return range.location != NSNotFound && range.location + range.length <= self.length
    }
}
