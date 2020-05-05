//
//  EngagementSDKDelegate.swift
//  EngagementSDK
//

import Foundation

/// A delegate which the `EngagementSDK` will inform about important events, such as setup errors.
@objc(LLEngagementSDKDelegate)
public protocol EngagementSDKDelegate: AnyObject {
    /**
     Called when the given `sdk` has failed to setup properly

     Upon receiving this call, the `sdk` should be considered invalid and unuseable.
     If caused by some transient failure like a poor network, a new `EngagementSDK` should
     be created.

     - parameter sdk: The `EngagementSDK` which encountered the setup error.
     - parameter error: The error encountered, possibly with information about how to resolve the issue.
     */
    @objc
    optional func sdk(_ sdk: EngagementSDK, setupFailedWithError error: Error)
    
    @objc optional func sdk(setupCompleted sdk: EngagementSDK)
}
