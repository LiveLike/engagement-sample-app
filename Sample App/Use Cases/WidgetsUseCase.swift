//
//  WidgetsViewController.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class WidgetsUseCase: UIViewController {

    private var sdk: EngagementSDK!
    private var session: ContentSession!
    
    private let clientID: String
    private let programID: String
    
    private let widgetViewController = WidgetViewController()
    
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
        addNotificationObservers()
    }
    
    deinit {
        removeNSNotificationObservers()
    }
    
    private func setupUI() {
        self.view.addSubview(widgetView)

        let safeArea = self.view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            widgetView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
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
        sdk = EngagementSDK.init(config: EngagementSDKConfig(clientID: clientID))
        sdk.delegate = self
        session = sdk.contentSession(config: SessionConfiguration(programID: programID))
        session.delegate = self
        
        widgetViewController.session = session
    }
    
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pauseSession),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resumeSession),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func removeNSNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func pauseSession() {
        session?.pause()
    }
    
    @objc func resumeSession() {
        session?.resume()
    }
    
}

// MARK: - EngagementSDKDelegate
extension WidgetsUseCase: EngagementSDKDelegate {
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

// MARK: - ContentSessionDelegate
extension WidgetsUseCase: ContentSessionDelegate {
    func playheadTimeSource(_ session: ContentSession) -> Date? {
        return nil
    }
    
    func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {}
    
    func widget(_ session: ContentSession, didBecomeReady jsonObject: Any) {}
    
    func widget(_ session: ContentSession, didBecomeReady widget: Widget) {}
    
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
