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
    private let cache: Cache

    init(reactionPacksUrl: URL, cache: Cache){
        self.reactionPacksUrl = reactionPacksUrl
        self.cache = cache
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
        }.then { reactionAssets in
            Promises.all(reactionAssets.map({ self.downloadAndCacheReactionImage(reactionAsset: $0) }))
        }
    }()

    private func loadReactionPack(atURL url: URL) -> Promise<ReactionPacksResource> {
        let resource = Resource<ReactionPacksResource>(get: url)
        return EngagementSDK.networking.load(resource)
    }

    private func downloadAndCacheReactionImage(reactionAsset: ReactionAsset) -> Promise<ReactionAsset> {
        return firstly {
            UIImage.download(url: reactionAsset.imageURL)
        }.then { image in
            self.cache.set(object: image, key: reactionAsset.imageURL.absoluteString)
        }.then { _ in
            return Promise(value: reactionAsset)
        }
    }

}

fileprivate extension ReactionAsset {
    init(reactionResource: ReactionResource) {
        self.id = ReactionID(fromString: reactionResource.id)
        self.imageURL = reactionResource.file
        self.name = reactionResource.name
    }
}

private enum ProgramChatReactionVendorError: LocalizedError {
    case invalidReactionPacksURL

    var errorDescription: String? {
        switch self {
        case .invalidReactionPacksURL:
            return "Invalid Reaction Packs URL"
        }
    }
}
