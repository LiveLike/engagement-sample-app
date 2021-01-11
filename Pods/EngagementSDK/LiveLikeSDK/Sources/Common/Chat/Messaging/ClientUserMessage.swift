//
//  ClientMessage.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-20.
//

import UIKit

struct ClientMessage {
    var message: String?
    var timeStamp: EpochTime? // represents player time source
    var reactions: ReactionVotes?
    var imageURL: URL?
    var imageSize: CGSize?
    
    init(message: String?, imageURL: URL?, imageSize: CGSize?) {
        self.message = message
        self.imageURL = imageURL
        self.imageSize = imageSize
    }
    
}
