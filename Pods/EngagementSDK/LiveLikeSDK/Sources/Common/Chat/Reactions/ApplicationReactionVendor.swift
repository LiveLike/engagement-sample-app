//
//  ApplicationReactionVendor.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 3/3/20.
//

import Foundation

class ApplicationReactionVendor: ReactionVendor {
    func getReactions() -> Promise<[ReactionAsset]> {
        return Promise(value: [])
    }

    init() {

    }

}
