//
//  ReactionVendor.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/19/19.
//

import Foundation

protocol ReactionVendor {
    func getReactions() -> Promise<[ReactionAsset]>
}
