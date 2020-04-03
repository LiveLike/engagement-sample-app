//
//  ChatReactionManager.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/19/19.
//

import Foundation
import UIKit

class ProgramChatReactionsVendor: ReactionVendor{

    private let programDetailVendor: ProgramDetailVendor
    private let cache: Cache

    init(programDetailVendor: ProgramDetailVendor, cache: Cache){
        self.programDetailVendor = programDetailVendor
        self.cache = cache
    }

    func getReactions() -> Promise<[ReactionAsset]> {
        return firstly {
            loadedReactions
        }.recover { error in
            log.error("ProgramChatReactionsVendor.getReactions() recovering from error: \(error.localizedDescription)")
            return Promise(value: [])
        }
    }

    private lazy var loadedReactions: Promise<[ReactionAsset]> = {
        return firstly {
            self.programDetailVendor.getProgramDetails()
        }.then { program -> Promise<ReactionPacksResource> in
            guard let reactionPackURL = program.reactionPacksUrl else {
                return Promise(error: NilError())
            }
            return self.loadReactionPack(atURL: reactionPackURL)
        }.then { reactionPacks -> Promise<[ReactionAsset]> in
            guard let reactionPack = reactionPacks.results.first else { return Promise(error: NilError())}
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
