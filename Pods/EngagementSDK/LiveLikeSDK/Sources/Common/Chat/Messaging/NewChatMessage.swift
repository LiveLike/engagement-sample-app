//
//  ChatUserMessage.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 3/18/21.
//

import UIKit

/// Is used to construct a chat message obect which can be passed
/// into the `sendMessage()` function of a `ChatSession`
public struct NewChatMessage {
    
    /// A local unique chat message identifier
    /// that is created prior to the message being published.
    /// This property can be used at a later time to map a published `ChatMessageID`
    public let messageID: String = UUID().uuidString.lowercased()
    
    /// Represents the text of a chat message, including sticker shortcodes
    public private(set) var text: String?
    
    /// A `URL` that references an image
    public private(set) var imageURL: URL?
    
    /// A suggested image size of the image in the chat message
    public private(set) var imageSize: CGSize?
    
    /// The `timeStamp` represents the time at which a chat message is to be shown to the user
    /// By default it is set to the time the message is published
    /// Set this to your own time stamp to enable Spoiler Prevention
    public var timeStamp: EpochTime?
    
    /// Init method for a chat message containing text or stickers
    /// - Parameters:
    ///   - message: text of the message, can also contain shortcodes for stickers
    ///   - timeStamp: an optional time source to enable Spoiler Prevention functionality
    public init(text: String, timeStamp: EpochTime? = nil) {
        self.text = text
        self.timeStamp = timeStamp
    }
    
    /// Init method for a chat message containing an image
    /// - Parameters:
    ///   - imageURL: a `URL` to the image
    ///   - imageSize: a preferable size of the image in the chat message
    ///   - timeStamp: an optional time source to enable Spoiler Prevention functionality
    public init(imageURL: URL, imageSize: CGSize, timeStamp: EpochTime? = nil) {
        self.imageURL = imageURL
        self.imageSize = imageSize
        self.timeStamp = timeStamp
    }
}
