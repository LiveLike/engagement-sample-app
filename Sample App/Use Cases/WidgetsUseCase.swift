//
//  WidgetsViewController.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class WidgetsUseCase: UIViewController {

    private var session: ContentSession?
    private let widgetViewController = WidgetViewController()
    private var clientID: String
    private var programID: String
    
    private let widgetView: UIView = {
        let widgetView = UIView()
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        widgetView.backgroundColor = .white
        return widgetView
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
        title = "Widgets"
        setupUI()
        setupEngagementSDK()
    }
    
    private func setupUI() {
        self.view.addSubview(widgetView)

        NSLayoutConstraint.activate([
            widgetView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
        
    }
    
    private func setupEngagementSDK() {
        
        let sdk = EngagementSDK.init(clientID: clientID,
                                     accessTokenStorage: self)
        let config = SessionConfiguration(programID: programID)
        session = sdk.contentSession(config: config, delegate: self)
        EngagementSDK.logLevel = .verbose
        
        widgetViewController.session = session
        session?.delegate = self
        
    }
    
}

// MARK: - EngagementSDK ContentSessionDelegate
extension WidgetsUseCase: ContentSessionDelegate {
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        print("Session status did change \(status)")
    }
    
    func session(_ session: ContentSession, didReceiveError error: Error) {
        print("Did receive error: \(error)")
    }
    
}

// MARK: AccessTokenStorage
extension WidgetsUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
