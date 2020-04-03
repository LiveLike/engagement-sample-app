//
//  LocalReactionsVendor.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/19/19.
//

import UIKit

class LocalReactionsVendor: ReactionVendor {
    func getReactions() -> Promise<[ReactionAsset]> {
        let chatReactions = [
            angry,
            cry,
            laughter,
            love
        ]
        return Promise(value: chatReactions)
    }
}

// MARK: - Reaction Definitions

private extension LocalReactionsVendor {
    func imageUrl(forResource resource: String) -> URL {
        return Bundle(for: LocalReactionsVendor.self).url(forResource: resource, withExtension: "png")!
    }

    var angry: ReactionAsset{
        return ReactionAsset(id: ReactionID(fromString: "angry"),
                             imageURL: imageUrl(forResource: "chatReactionAngry"),
                             name: "chatReactionAngry")
    }
    var cry: ReactionAsset{
        return ReactionAsset(id: ReactionID(fromString: "cry"),
                             imageURL: imageUrl(forResource: "chatReactionCry"),
                             name: "chatReactionCry")
    }
    var laughter: ReactionAsset{
        return ReactionAsset(id: ReactionID(fromString: "laughter"),
                             imageURL: imageUrl(forResource: "chatReactionLaughter"),
                             name: "chatReactionLaughter")
    }
    var love: ReactionAsset{
        return ReactionAsset(id: ReactionID(fromString: "love"),
                             imageURL: imageUrl(forResource: "chatReactionLove"),
                             name: "chatReactionLove")
    }
}
