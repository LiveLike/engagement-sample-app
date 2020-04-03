//
//  ClientMessage.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-20.
//

import UIKit

struct ClientMessage {
    let message: String?
    let timeStamp: EpochTime? // represents player time source
    let badge: Badge?
    let reactions: ReactionVotes
    let imageURL: URL?
    let imageSize: CGSize?
}
