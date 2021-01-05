//
//  ChatReactionModels.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/19/19.
//

import UIKit

// MARK: - API

/// Represents the reaction resource from the backend
struct ReactionResource: Decodable {
    let id: String
    let file: URL
    let name: String
}

/// Represents the reaction pack resource from the backend
struct ReactionPackResource: Decodable {
    let id: String
    let emojis: [ReactionResource]
}

struct ReactionPacksResource: Decodable {
    let results: [ReactionPackResource]
}

// MARK: Data

/// The id used to identify reactions
struct ReactionID: Hashable {

    private let internalID: String

    var asString: String {
        return internalID
    }

    init(fromString id: String){
        internalID = id
    }
}

extension ReactionID: Equatable {
    static func == (lhs: ReactionID, rhs: ReactionID) -> Bool {
        return lhs.internalID == rhs.internalID
    }
}

struct ReactionAsset {
    let id: ReactionID
    let imageURL: URL
    let name: String
}

/// Represents a single vote on a reaction
struct ReactionVote {
    struct ID: Hashable {
        let internalID: AnyHashable
        init(_ hashable: AnyHashable) {
            self.internalID = hashable
        }
    }

    let voteID: ID
    let reactionID: ReactionID
    let isMine: Bool
}

/// Represents the collection of all reaction votes
struct ReactionVotes {
    @ReadWriteAtomic var allVotes: [ReactionVote]

    var reactionIDs: Set<ReactionID> {
        return Set(allVotes.map { $0.reactionID })
    }

    func voteCount(forID id: ReactionID) -> Int {
        return allVotes.filter({$0.reactionID == id}).count
    }

    func isMine(forID id: ReactionID) -> Bool {
        return allVotes.contains(where: { $0.reactionID == id && $0.isMine})
    }

    static let empty: ReactionVotes = ReactionVotes(allVotes: [])
}

// MARK: - View

/// Represents a reaction button
class ReactionButtonViewModel {
    let id: ReactionID
    /// How many user's voted for reaction with `id` (including myself)
    var voteCount: Int
    /// Did I vote for reaction with `id`
    var isMine: Bool
    /// The reaction vote id of the local client if it exists
    var myVoteID: ReactionVote.ID?
    /// The UIImage of this reaction
    let imageURL: URL
    /// The label used for Accessibility
    let name: String

    init(
        id: ReactionID,
        voteCount: Int,
        isMine: Bool,
        myVoteID: ReactionVote.ID?,
        imageURL: URL,
        name: String
    ) {
        self.id = id
        self.voteCount = voteCount
        self.isMine = isMine
        self.myVoteID = myVoteID
        self.imageURL = imageURL
        self.name = name
    }
}

/// Represents all of a chat message's reaction buttons
struct ReactionButtonListViewModel {
    var reactions: [ReactionButtonViewModel]

    func image(forID id: ReactionID) -> URL? {
        return reactions.first(where: { $0.id == id })?.imageURL
    }

    func isMine(forID id: ReactionID) -> Bool {
        return reactions.contains(where: { $0.id == id && $0.isMine })
    }

    func voteCount(forID id: ReactionID) -> Int {
        return reactions.first(where: {$0.id == id})?.voteCount ?? 0
    }

    func myVoteID() -> ReactionVote.ID? {
        return reactions.first(where: { $0.isMine })?.myVoteID
    }

    var totalReactionsCount: Int {
        return reactions.map({$0.voteCount}).reduce(0, +)
    }

    init(reactions: [ReactionButtonViewModel]) {
        self.reactions = reactions
    }

    init(reactionAssets: [ReactionAsset]) {
        self.reactions = reactionAssets.map { reactionAsset in
            return ReactionButtonViewModel(
                id: reactionAsset.id,
                voteCount: 0,
                isMine: false,
                myVoteID: nil,
                imageURL: reactionAsset.imageURL,
                name: reactionAsset.name
            )
        }
    }

    init(reactionAssets: [ReactionAsset], reactionVotes: ReactionVotes) {
        self.reactions = reactionAssets.map { reactionAsset in
            let reactionViewModel = ReactionButtonViewModel(
                id: reactionAsset.id,
                voteCount: reactionVotes.voteCount(forID: reactionAsset.id),
                isMine: reactionVotes.isMine(forID: reactionAsset.id),
                myVoteID: reactionVotes.allVotes.first(where: { $0.isMine })?.voteID,
                imageURL: reactionAsset.imageURL,
                name: reactionAsset.name)
            return reactionViewModel
        }
    }
}
