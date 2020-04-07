//
//  ChatModule.swift
//  Sample App
//
//  Created by Jelzon Monzon on 4/6/20.
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class ChatModule: UIViewController {
    
    private var sdk: EngagementSDK!
    private var session: ContentSession!
    
    private let clientID: String
    private let programID: String
    
    private let chatViewController = ChatViewController()
    
    init(
        clientID: String,
        programID: String
    ) {
        self.clientID = clientID
        self.programID = programID
        super.init(nibName: nil, bundle: nil)
        self.title = "Chat Module"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLayout()
        configureTheme()
        
        sdk = EngagementSDK(clientID: clientID)
        sdk.delegate = self
        session = sdk.contentSession(config: SessionConfiguration(programID: programID))
        session.delegate = self
        
        chatViewController.session = session
    }
    
    private func configureLayout() {
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatViewController.view)
        addChild(chatViewController)
        chatViewController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            chatViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            chatViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureTheme() {
        let theme = Theme()
        theme.chatBodyColor = .white
        theme.chatImageWidth = 20.0
        theme.chatImageHeight = 20.0
        theme.chatImageCornerRadius = 0.0
        theme.chatImageTrailingMargin = 5.0
        theme.chatImageVerticalAlignment = .center
        theme.messageDynamicWidth = false
        theme.messageBackgroundColor = .white
        theme.messageSelectedColor = .white
        theme.messageTextColor = UIColor(red: 95.0 / 256.0, green: 95.0 / 256.0, blue: 95.0 / 256.0, alpha: 1.0)
        theme.usernameTextColor = .black
        theme.messageCornerRadius = 0.0
        theme.messagePadding = 0.0
        theme.messageMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        theme.chatLeadingMargin = 0.0
        theme.chatTrailingMargin = 0.0
        theme.messageTopBorderHeight = 2.0
        theme.messageTopBorderColor = UIColor(red: 239.0 / 256.0, green: 239.0 / 256.0, blue: 244.0 / 256.0, alpha: 1.0)
        theme.messageBottomBorderHeight = 0.0
        theme.messageBottomBorderColor = .clear
        theme.chatReactions.displayCountsColor = UIColor(red: 152.0 / 256.0, green: 152.0 / 256.0, blue: 152.0 / 256.0, alpha: 1.0)
        theme.messageReactionsVerticalOffset = 11.0
        theme.chatCornerRadius = 20.0
        theme.reactionsPopupHorizontalAlignment = .center
        theme.reactionsPopupHorizontalOffset = 0.0
        theme.reactionsPopupVerticalOffset = -26.0
        theme.reactionsPopupCornerRadius = 18
        theme.chatInputPlaceholderTextColor = UIColor(red: 142.0 / 256.0, green: 142.0 / 256.0, blue: 147.0 / 256.0, alpha: 1.0)
        theme.chatInputBackgroundColor = UIColor(red: 239.0 / 256.0, green: 239.0 / 256.0, blue: 244.0 / 256.0, alpha: 1.0)
        theme.chatMessageTimestampTextColor = .gray
        theme.reactionsPopupBackground = .lightGray
    
        chatViewController.setTheme(theme)
    }
    
}

extension ChatModule: EngagementSDKDelegate {
    func sdk(_ sdk: EngagementSDK, setupFailedWithError error: Error) {
        let alert = UIAlertController(
            title: "EngagementSDK Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ChatModule: ContentSessionDelegate {
    func session(_ session: ContentSession, didReceiveError error: Error) {
        let alert = UIAlertController(
            title: "ContentSession Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
