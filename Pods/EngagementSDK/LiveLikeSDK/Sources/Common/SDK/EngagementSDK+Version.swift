//
//  Version.swift
//  EngagementSDKDemo
//
//  Created by Cory Sullivan on 2019-04-23.
//

import Foundation
// swiftlint:disable force_cast
extension EngagementSDK {
    public static var versionAndBuild: String {
        return "\(version) (\(build))"
    }

    public static var version: String {
        return Bundle(for: EngagementSDK.self)
            .object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as! String
    }

    public static var build: String {
        return Bundle(for: EngagementSDK.self)
            .object(forInfoDictionaryKey: "CFBundleVersion")
            as! String
    }
}
