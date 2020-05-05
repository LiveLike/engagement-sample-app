//
//  ContentSessionProtocol.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dams on 2019-01-18.
//

import AVFoundation
import Foundation

/// Unix epoch. The number of seconds that have elapsed since January 1, 1970 (midnight UTC/GMT), not counting leap seconds
typealias EpochTime = TimeInterval

/**
 A `ContentSession` instance represents a program item, usually related to a live feed.

 `ContentSession` instance needs to be set in both `ChatViewController` and `WidgetViewController` to receive chat/widgets.

 */
@objc(LLContentSession)
public protocol ContentSession {
    /**
     A unique ID to identify the content currently being played.
     */
    var programID: String { get }
    
    /**
     The status of the `ContentSession`
     */
    var status: SessionStatus { get }

    /// An object that acts as the delegate of the content session.
    var delegate: ContentSessionDelegate? { get set }

    /**
     Pauses both Chat and Widget components.

     Pausing the Engagement SDK stops new widgets and chat message from being displayed. Any widgets currently being displayed, will be dimissed.

     Widgets will still be received by the Engagement SDK, but will only be displayed after `resume()` is called, unless they have timed out.
     */
    func pause()

    /**
     Resumes both Chat and Widget components.
     */
    func resume()

    /**
     Closes the current session.
     */
    func close()

    func install(plugin: Plugin)
    
    /// Sets an image for the user's chat messages in the current chat room
    func updateUserChatRoomImage(url: URL, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    // MARK: - Unavailable
    
    /// A unique ID to identify the chat room that is currently entered
    @available(iOS, unavailable, message: "Moved to ChatSession")
    var currentChatRoomID: String? { get }

    /// The set of chat room IDs that are currently joined
    @available(iOS, unavailable, message: "Moved to ChatSession")
    var joinedChatRoomIDs: Set<String> { get }

    /// Joins and displays the room on a ChatViewController
    @available(iOS, unavailable, message: "Moved to ChatSession")
    func enterChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    /// Leave a room to stop receiving updates
    @available(iOS, unavailable, message: "Moved to ChatSession")
    func leaveChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    /// Join the room to begin receiving updates
    @available(iOS, unavailable, message: "Moved to ChatSession")
    func joinChatRoom(roomID: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void)

    /// Returns a list of chat messages with and since a given timestamp
    @available(iOS, unavailable, message: "Moved to ChatSession")
    func getLatestChatMessages(
        forRoom roomID: String,
        startTimetoken timetoken: TimeToken,
        completion: @escaping ([ChatMessage]) -> Void,
        failure: @escaping (Error) -> Void
    )

    @available(iOS, unavailable, message: "Moved to ChatSession")
    func getLatestChatMessages(
        forRoom roomID: String,
        since timestamp: Date,
        completion: @escaping ([ChatMessage]) -> Void,
        failure: @escaping (Error) -> Void
    )
    
    /// Provides the count of chat messages
    /// - Parameters:
    ///   - roomID: The id of the room
    ///   - timetoken: The timetoken of the earliest message to start counting from
    ///   - completion: Completion block that returns the count of chat messages
    ///   - failure: Failure block
    @available(iOS, unavailable, message: "Moved to Chat Session")
    func getChatMessageCount(
        forRoom roomID: String,
        startTimetoken timetoken: TimeToken,
        completion: @escaping (Int) -> Void,
        failure: @escaping (Error) -> Void
    )

    @available(iOS, unavailable, message: "Moved to Chat Session")
    func getChatMessageCount(
        forRoom roomID: String,
        since timestamp: Date,
        completion: @escaping (Int) -> Void,
        failure: @escaping (Error) -> Void
    )
}
