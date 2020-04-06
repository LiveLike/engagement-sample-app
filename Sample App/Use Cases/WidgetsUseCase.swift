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
    
    private var widgetView: UIView = {
        let widgetView = UIView()
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        widgetView.backgroundColor = .white
        return widgetView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Widgets"
        setUpUI()
        setUpEngagementSDK()
    }
    
    private func setUpUI() {
        self.view.addSubview(widgetView)
        
        let safeArea = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            widgetView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            widgetView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            widgetView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
        
    }
    
}

// MARK: - EngagementSDK ContentSessionDelegate
extension WidgetsUseCase: ContentSessionDelegate {
     private func setUpEngagementSDK() {
        
        guard let clientID = Defaults.activeClientID,
            let programID = Defaults.activeProgramID else {
            return
        }
        
        let sdk = EngagementSDK.init(clientID: clientID,
                                     accessTokenStorage: self)
        let config = SessionConfiguration(programID: programID)
        session = sdk.contentSession(config: config, delegate: self)
        EngagementSDK.logLevel = .verbose
        
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
extension WidgetsUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
