//
//  ChatAndWidgetsUseCase.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class ChatAndWidgetsUseCase: UIViewController {

    private var session: ContentSession?
    private let widgetViewController = WidgetViewController()
    private let chatViewController = ChatViewController()
    private var clientID: String
    private var programID: String
    
    private let widgetView: UIView = {
        let widgetView = UIView()
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        return widgetView
    }()
    
    private let chatView: UIView = {
        let chatView = UIView()
        chatView.translatesAutoresizingMaskIntoConstraints = false
        return chatView
    }()
    
    init(clientID: String, programID: String) {
        
        self.clientID = clientID
        self.programID = programID
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Widgets and Chat"
        setupUI()
        setupEngagementSDK()
    }
    
    private func setupUI() {
        self.view.addSubview(chatView)
        self.view.addSubview(widgetView)
        
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            widgetView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor)
        ])
        
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
        
    }
    
    private func setupEngagementSDK() {
        
        let sdk = EngagementSDK.init(clientID: clientID,
                                     accessTokenStorage: self)
        let config = SessionConfiguration(programID: programID)
        session = sdk.contentSession(config: config, delegate: self)
        
        widgetViewController.session = session
        chatViewController.session = session
        session?.delegate = self
        
    }

}

// MARK: - ContentSessionDelegate
extension ChatAndWidgetsUseCase: ContentSessionDelegate {
    
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        print("Session status did change \(status)")
    }
    
    func session(_ session: ContentSession, didReceiveError error: Error) {
        print("Did receive error: \(error)")
    }
 
}

// MARK: AccessTokenStorage
extension ChatAndWidgetsUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
