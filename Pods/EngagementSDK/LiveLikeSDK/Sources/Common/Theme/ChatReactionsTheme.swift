//
//  ChatReactionsTheme.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 9/23/19.
//

import UIKit

@objc public class ChatReactionsTheme: NSObject {
    /// The text color for the counts of each reaction on the panel for selecting a reaction
    @objc public var panelCountsColor: UIColor
    /// The text color for the counts of each reaction on the chat bubble reactions display
    @objc public var displayCountsColor: UIColor

    init(panelCountsColor: UIColor,
         displayCountsColor: UIColor){
        self.panelCountsColor = panelCountsColor
        self.displayCountsColor = displayCountsColor
    }
}
