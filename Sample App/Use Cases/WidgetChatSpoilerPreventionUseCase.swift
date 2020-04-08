//
//  ChatAndWidgetsUseCase.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK
import AVKit

class WidgetChatSpoilerPreventionUseCase: UIViewController {

    private var session: ContentSession?
    private let widgetViewController = WidgetViewController()
    private let chatViewController = ChatViewController()
    private var clientID: String
    private var programID: String
    private let avPlayerViewController = AVPlayerViewController()
    
    /// ℹ️ The AVPlayer URL would be the same URL that is used as the source
    /// video in the LiveLike Producer site
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
    }
    
    private func setupUI() {
        
        // Add widgetViewController as child view controller
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
        
        avPlayerViewController.view.frame = CGRect(x: 0, y: 0, width: videoPlayerView.bounds.width, height: videoPlayerView.bounds.height)
        videoPlayerView.addSubview(avPlayerViewController.view)
        self.addChild(avPlayerViewController)
        
        videoPlayer.play()
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
extension WidgetChatSpoilerPreventionUseCase: ContentSessionDelegate {
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
