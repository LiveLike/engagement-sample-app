//
//  ContentSessionDelegate.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-02-25.
//

import Foundation

/**
 Content Session delegate.
 */
public protocol ContentSessionDelegate: AnyObject {
    
    /**
     A real-world reference date used by the EngagementSDK for spoiler-free sync feature.

     - note: This delegate function needs to be implemented to make use of sync.

     - returns: Date of the current video playhead position. Nil is considered to be unsynced.
     */
    func playheadTimeSource(_ session: ContentSession) -> Date?

    /**
     Tells the delegate the `ContentSession` status did change

      - Parameters:
        - session: The content session object informing the delegate of this event
        - status: The status of the content session
     */
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus)

    /**
     Tells the delegate that the content session encountered an error

     - Parameters:
       - session: The content session object informing the delegate of this event
       - error: The error that the content session encountered
     */
    func session(_ session: ContentSession, didReceiveError error: Error)
    
    func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage)
    
    /// Notifies the delegate that a widget was recieved on the `ContentSession`
    /// - Parameters:
    ///   - session: The content session object informing the delegate of this event
    ///   - jsonObject: The JSON object of the widget that became ready
    func widget(_ session: ContentSession, didBecomeReady jsonObject: Any)
    
    /// Notifies the delegate that a widget was recieved on the `ContentSession`
    /// - Parameters:
    ///   - session: The content session object informing the delegate of this event
    ///   - widget: The `WidgetViewModel` of the widget that became ready
    func widget(_ session: ContentSession, didBecomeReady widget: Widget)
}
