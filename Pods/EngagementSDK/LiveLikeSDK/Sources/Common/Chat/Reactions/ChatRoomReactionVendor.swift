//
//  ChatRoomReactionVendor.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 5/27/20.
//

import Foundation
import UIKit

class ChatRoomReactionVendor: ReactionVendor {
    private let reactionPacksUrl: URL

    init(reactionPacksUrl: URL){
        self.reactionPacksUrl = reactionPacksUrl
    }

    func getReactions() -> Promise<[ReactionAsset]> {
        return firstly {
            loadedReactions
        }.recover { error in
            log.error("ChatRoomReactionVendor.getReactions() recovering from error: \(error.localizedDescription)")
            return Promise(value: [])
        }
    }

    private lazy var loadedReactions: Promise<[ReactionAsset]> = {
        return firstly {
            return self.loadReactionPack(atURL: reactionPacksUrl)
        }.then { reactionPacks -> Promise<[ReactionAsset]> in
            guard let reactionPack = reactionPacks.results.first else {
                log.debug("Reaction Packs Resource is Empty")
                return Promise(value: [])
            }
            let reactionAssets = reactionPack.emojis.map({ ReactionAsset(reactionResource: $0) })
            return Promise(value: reactionAssets)
        }
    }()

    private func loadReactionPack(atURL url: URL) -> Promise<ReactionPacksResource> {
        let resource = Resource<ReactionPacksResource>(get: url)
        return EngagementSDK.networking.load(resource)
    }
}

fileprivate extension ReactionAsset {
    init(reactionResource: ReactionResource) {
        self.id = ReactionID(fromString: reactionResource.id)
        self.imageURL = reactionResource.file
        self.name = reactionResource.name
    }
}
