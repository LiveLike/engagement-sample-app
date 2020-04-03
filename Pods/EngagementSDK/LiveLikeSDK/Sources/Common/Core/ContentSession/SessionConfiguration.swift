//
//  SessionConfiguration.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-29.
//

import Foundation

/// A configuration object that defines the properties for a `ContentSession`
@objc(LLSessionConfiguration)
public class SessionConfiguration: NSObject {
    /// A unique ID to identify the content currently being played.
    @objc public let programID: String

    /// The preloaded chat history limit. Default is 50, up to a maximum of 200.
    @objc public let chatHistoryLimit: Int

    /// A set of flags that modify the behavior of Widgets
    @objc public let widgetConfig: WidgetConfig

    ///
    @objc public init(programID: String, chatHistoryLimit: Int, widgetConfig: WidgetConfig) {
        self.programID = programID
        self.chatHistoryLimit = chatHistoryLimit
        self.widgetConfig = widgetConfig
    }

    ///
    @objc public convenience init(programID: String, chatHistoryLimit: Int){
        self.init(programID: programID, chatHistoryLimit: chatHistoryLimit, widgetConfig: .default)
    }

    ///
    @objc public convenience init(programID: String) {
        self.init(programID: programID, chatHistoryLimit: 50, widgetConfig: .default)
    }
}
