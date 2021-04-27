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
    
    /// Represents the text of a chat message, including sticker shortcodes
    public let text: String?
    
    /// A `URL` that references an image
    public let imageURL: URL?
    
    /// A suggested image size of the image in the chat message
    public let imageSize: CGSize?
    
    /// The `timeStamp` represents the time at which a chat message is to be shown to the user
    /// By default it is set to the time the message is published
    /// In the case of Spoiler Prevention functionality being turned on, its value is provided by the
    /// `syncTimeSource` set in `ChatSessionConfig` or `SessionConfiguration`
    var timeStamp: EpochTime?
    
    /// Init method for a chat message containing text or stickers
    /// - Parameters:
    ///   - message: text of the message, can also contain shortcodes for stickers
    public init(text: String) {
        self.text = text
        self.imageURL = nil
        self.imageSize = nil
    }
    
    /// Init method for a chat message containing an image
    /// - Parameters:
    ///   - imageURL: a `URL` to the image
    ///   - imageSize: a preferable size of the image in the chat message
    public init(imageURL: URL, imageSize: CGSize) {
        self.imageURL = imageURL
        self.imageSize = imageSize
        self.text = nil
    }
    
    /// Init method for a chat message containing an image
    /// - Parameters:
    ///   - imageData: `UIImage` object represented in `Data` type
    ///   - imageSize: a preferable size of the image in the chat message
    public init(imageData: Data, imageSize: CGSize) {
        self.text = nil
        self.imageSize = imageSize
        
        let imageName = "\(Int64(NSDate().timeIntervalSince1970 * 1000)).gif"
        let fileURL = "mock:\(imageName)"
        Cache.shared.set(object: imageData, key: fileURL, completion: nil)
        self.imageURL = URL(string: fileURL)
    }
}
