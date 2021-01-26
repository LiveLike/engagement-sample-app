//
//  LiveLikeSDKBuilder.swift
//  LiveLikeTestApp
//
//  Created by Mike Moloksher on 1/21/21.
//

import EngagementSDK
import UIKit

final class LiveLikeSDKBuilder {
    private let clientID: String
    private let programID: String
    private var sdk: EngagementSDK
    private var session: ContentSession

    init(clientID: String, programID: String) {
        self.clientID = clientID
        self.programID = programID

        let config = EngagementSDKConfig(clientID: clientID)
        sdk = EngagementSDK(config: config)
        session = sdk.contentSession(config: SessionConfiguration(programID: programID))
    }

    func getChatViewController() -> ChatViewController {
        let chatVC = ChatViewController()
        chatVC.session = session
        return chatVC
    }

    func makeTimelineViewController() -> CustomWidgetTimelineViewController {
        let timelineViewController = CustomWidgetTimelineViewController(session: session)
        return timelineViewController
    }
}
