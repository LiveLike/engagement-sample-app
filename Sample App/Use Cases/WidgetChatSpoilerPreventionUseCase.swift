//
//  ChatAndWidgetsUseCase.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//
//  This use case showcases Widgets, Chat and Spoiler Prevention functionality working
//  together in one View Controller.
//  Spoiler Prevention - https://docs.livelike.com/docs/ios-spoiler-free-sync

import UIKit
import EngagementSDK
import AVKit

class WidgetChatSpoilerPreventionUseCase: UIViewController {

    private var sdk: EngagementSDK!
    private var session: ContentSession!
    
    private let clientID: String
    private let programID: String
    
    private let widgetViewController = WidgetViewController()
    private let chatViewController = ChatViewController()
    private let avPlayerViewController = AVPlayerViewController()
    
    /// ℹ️ The AVPlayer URL would be the same URL that is used as the source
    /// video in the LiveLike Producer site. Read more about it here https://docs.livelike.com/docs/ios-spoiler-free-sync
    private let videoPlayer: AVPlayer = AVPlayer(url: URL(string: "https://cf-streams.livelikecdn.com/live/colorbars-angle1/index.m3u8")!)
    
    private let videoPlayerView: UIView = {
        let videoPlayerView = UIView()
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        return videoPlayerView
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
        title = "Widgets, Chat and Spoiler Prevention"
        setupUI()
        setUpVideoPlayer()
        setupEngagementSDK()
        addNotificationObservers()
    }
    
    deinit {
        removeNSNotificationObservers()
    }
    
    private func setupUI() {
        
        addChild(widgetViewController)
        widgetViewController.didMove(toParent: self)
        widgetViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        chatViewController.shouldDisplayDebugVideoTime = true
        addChild(chatViewController)
        chatViewController.didMove(toParent: self)
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(videoPlayerView)
        self.view.addSubview(chatViewController.view)
        self.view.addSubview(widgetViewController.view)
        
        let safeArea = self.view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            videoPlayerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0.0),
            videoPlayerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0.0),
            videoPlayerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0.0),
            videoPlayerView.heightAnchor.constraint(equalTo: videoPlayerView.widthAnchor, multiplier: 9/16),
            
            chatViewController.view.topAnchor.constraint(equalTo: videoPlayerView.bottomAnchor),
            chatViewController.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            chatViewController.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            chatViewController.view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            
            widgetViewController.view.topAnchor.constraint(equalTo: videoPlayerView.bottomAnchor),
            widgetViewController.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            widgetViewController.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            widgetViewController.view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
    
    private func setUpVideoPlayer() {
        avPlayerViewController.player = videoPlayer
        avPlayerViewController.showsPlaybackControls = false
        
        avPlayerViewController.view.frame = CGRect(x: 0,
                                                   y: 0,
                                                   width: videoPlayerView.bounds.width,
                                                   height: videoPlayerView.bounds.height)
        videoPlayerView.addSubview(avPlayerViewController.view)
        self.addChild(avPlayerViewController)
        
        videoPlayer.play()
    }
    
    private func setupEngagementSDK() {
        sdk = EngagementSDK.init(config: EngagementSDKConfig(clientID: clientID))
        sdk.delegate = self
        session = sdk.contentSession(config: SessionConfiguration(programID: programID))
        session.delegate = self
        
        widgetViewController.session = session
        chatViewController.session = session
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
extension WidgetChatSpoilerPreventionUseCase: EngagementSDKDelegate {
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
extension WidgetChatSpoilerPreventionUseCase: ContentSessionDelegate {
    func contentSession(_ session: ContentSession, didReceiveWidget widget: WidgetModel) { }
    
    func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {
        
    }
    
    func widget(_ session: ContentSession, didBecomeReady jsonObject: Any) {
        
    }
    
    func widget(_ session: ContentSession, didBecomeReady widget: Widget) {
        
    }
    
    /// ℹ️ This func is required to turn on Spoiler Prevention functionality
    /// Read more about it here https://docs.livelike.com/docs/ios-spoiler-free-sync
    func playheadTimeSource(_ session: ContentSession) -> Date? {
        return avPlayerViewController.player?.programDateTime ?? Date()
    }
    
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        print("Session status did change \(status)")
    }
    
    func session(_ session: ContentSession, didReceiveError error: Error) {
        print("Did receive error: \(error)")
    }
 
}

// MARK: AccessTokenStorage
extension WidgetChatSpoilerPreventionUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
