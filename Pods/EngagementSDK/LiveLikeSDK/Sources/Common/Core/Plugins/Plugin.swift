//
//  Plugin.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/6/19.
//

import Foundation

/// :nodoc:
@objc public protocol Plugin {}

protocol ResolveablePlugin {
    func resolve(_ dependencies: [String: Any]) -> PluginRoot?
}
