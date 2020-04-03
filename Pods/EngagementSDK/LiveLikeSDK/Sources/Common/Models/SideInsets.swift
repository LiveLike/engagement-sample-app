//
//  SideInsets.swift
//  EngagementSDK
//
//  Created by Xavi Matos on 9/23/19.
//

import Foundation
import CoreGraphics

@objc(LLSideInsets)
public class SideInsets: NSObject {
    public let left: CGFloat
    public let right: CGFloat
    
    public init(left: CGFloat, right: CGFloat) {
        self.left = left
        self.right = right
    }
    
    public static var zero: SideInsets { return .init(left: 0, right: 0) }
}
