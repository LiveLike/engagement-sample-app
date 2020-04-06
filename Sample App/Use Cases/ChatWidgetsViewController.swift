//
//  ChatWidgetsViewController.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class ChatWidgetsViewController: UIViewController {

    private var session: ContentSession?
    private let widgetViewController = WidgetViewController()
    private let chatViewController = ChatViewController()
    
    private var widgetView: UIView = {
        let widgetView = UIView()
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        return widgetView
    }()
    
    private var chatView: UIView = {
        let chatView = UIView()
        chatView.translatesAutoresizingMaskIntoConstraints = false
        return chatView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Widgets and Chat"
        setUpUI()
        setUpEngagementSDK()
    }
    
    private func setUpUI() {
        self.view.addSubview(chatView)
        self.view.addSubview(widgetView)
        
        let safeArea = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            chatView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            chatView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            chatView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            widgetView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            widgetView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            widgetView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
        
    }

}

// MARK: - ContentSessionDelegate
extension ChatWidgetsViewController: ContentSessionDelegate {
     private func setUpEngagementSDK() {
        
        guard let clientID = Defaults.activeClientID,
            let programID = Defaults.activeProgramID else {
            return
        }
        
        let sdk = EngagementSDK.init(clientID: clientID,
                                     accessTokenStorage: self)
        let config = SessionConfiguration(programID: programID)
        session = sdk.contentSession(config: config, delegate: self)
        
        // Add widgetViewController as child view controller
        addChild(widgetViewController)
        widgetView.addSubview(widgetViewController.view)
        widgetViewController.didMove(toParent: self)

        widgetViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widgetViewController.view.bottomAnchor.constraint(equalTo: widgetView.bottomAnchor),
            widgetViewController.view.topAnchor.constraint(equalTo: widgetView.topAnchor),
            widgetViewController.view.trailingAnchor.constraint(equalTo: widgetView.trailingAnchor),
            widgetViewController.view.leadingAnchor.constraint(equalTo: widgetView.leadingAnchor)
        ])
        widgetViewController.session = session
        
        addChild(chatViewController)
        chatView.addSubview(chatViewController.view)
        chatViewController.didMove(toParent: self)

        // Apply constraints to fill the chatView container
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatViewController.view.bottomAnchor.constraint(equalTo: chatView.bottomAnchor),
            chatViewController.view.topAnchor.constraint(equalTo: chatView.topAnchor),
            chatViewController.view.trailingAnchor.constraint(equalTo: chatView.trailingAnchor),
            chatViewController.view.leadingAnchor.constraint(equalTo: chatView.leadingAnchor)
        ])
        
        chatViewController.session = session
        session?.delegate = self
        
    }
    
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        print("Session status did change \(status)")
    }
    
    func session(_ session: ContentSession, didReceiveError error: Error) {
        print("Did receive error: \(error)")
    }
    
    func playheadTimeSource() -> Date {
        return Date()
    }
}

// MARK: AccessTokenStorage
extension ChatWidgetsViewController: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
