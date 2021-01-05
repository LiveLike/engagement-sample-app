//
//  CreateEnterChatRoomUseCase.swift
//  Sample App
//
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class CreateEnterChatRoomUseCase: UIViewController {
    
    private var sdk: EngagementSDK!
    private let clientID: String
    private let programID: String
    private var currentRoomID: String?
    private var userChatRooms: [ChatRoomInfo]?
    
    private var chatSession: ChatSession? {
        didSet {
            if let chatSession = chatSession {
                roomIdLabel.text = "id: \(chatSession.roomID)"
                roomTitleLabel.text = "title: \(chatSession.title ?? "No Title")"
                leaveRoomBtn.isHidden = false
            }
        }
    }

    private let chatViewController = ChatViewController()
    private let createRoomButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .groupTableViewBackground
        button.setTitle("Create Chat Room", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let chooseRoomToEnterBtn: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.setTitle("Choose Room To Enter", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(chooseRoomToEnter), for: .touchUpInside)
        return button
    }()
    
    private let leaveRoomBtn: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.setTitle("Leave Room", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(leaveRoom), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private let chooseRoomBtnHolder: UIView = {
        let chooseRoomBtnHolder = UIView(frame: .zero)
        chooseRoomBtnHolder.translatesAutoresizingMaskIntoConstraints = false
        return chooseRoomBtnHolder
    }()

    private let roomTitle: UITextField = {
        let roomTitle: UITextField = UITextField()
        roomTitle.placeholder = "Optional Chat Room Title"
        roomTitle.translatesAutoresizingMaskIntoConstraints = false
        roomTitle.borderStyle = .line
        roomTitle.font = UIFont.systemFont(ofSize: 12.0)
        return roomTitle
    }()

    private let roomIdLabel: UILabel = {
        let roomIdLabel = UILabel()
        roomIdLabel.textColor = .white
        roomIdLabel.translatesAutoresizingMaskIntoConstraints = false
        roomIdLabel.font = UIFont.systemFont(ofSize: 8.0)
        return roomIdLabel
    }()

    private let roomTitleLabel: UILabel = {
        let roomTitleLabel = UILabel()
        roomTitleLabel.textColor = .white
        roomTitleLabel.font = UIFont.systemFont(ofSize: 8.0)
        roomTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return roomTitleLabel
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
        title = "Create / Join Chat Rooms"
        setupUI()
        setupEngagementSDK()
        addNotificationObservers()
    }
    
    deinit {
        removeNSNotificationObservers()
    }
    
    private func setupUI() {
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white

        addChild(chatViewController)

        view.addSubview(chatViewController.view)
        chooseRoomBtnHolder.addSubview(chooseRoomToEnterBtn)
        view.addSubview(chooseRoomBtnHolder)
        view.addSubview(createRoomButton)
        view.addSubview(roomTitle)
        view.addSubview(roomIdLabel)
        view.addSubview(roomTitleLabel)
        view.addSubview(leaveRoomBtn)
        

        NSLayoutConstraint.activate([
            chatViewController.view.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 90.0),
            chatViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50.0),

            createRoomButton.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20.0),
            createRoomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
            createRoomButton.heightAnchor.constraint(equalToConstant: 50.0),
            createRoomButton.widthAnchor.constraint(equalToConstant: 150.0),
            roomTitle.leadingAnchor.constraint(equalTo: createRoomButton.trailingAnchor, constant: 10.0),
            roomTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0),
            roomTitle.centerYAnchor.constraint(equalTo: createRoomButton.centerYAnchor),

            roomIdLabel.topAnchor.constraint(equalTo: chatViewController.view.topAnchor, constant: 10.0),
            roomIdLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0),
            roomTitleLabel.topAnchor.constraint(equalTo: roomIdLabel.bottomAnchor, constant: 5.0),
            roomTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0),
            
            leaveRoomBtn.topAnchor.constraint(equalTo: roomTitleLabel.bottomAnchor, constant: 5),
            leaveRoomBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            leaveRoomBtn.heightAnchor.constraint(equalToConstant: 50.0),
            leaveRoomBtn.widthAnchor.constraint(equalToConstant: 100.0),
            
            chooseRoomBtnHolder.widthAnchor.constraint(equalTo: view.widthAnchor),
            chooseRoomBtnHolder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chooseRoomBtnHolder.heightAnchor.constraint(equalToConstant: 50.0),
            chooseRoomBtnHolder.topAnchor.constraint(equalTo: chatViewController.view.bottomAnchor),
            
            chooseRoomToEnterBtn.widthAnchor.constraint(equalToConstant: 300),
            chooseRoomToEnterBtn.centerXAnchor.constraint(equalTo: chooseRoomBtnHolder.centerXAnchor),
            chooseRoomToEnterBtn.heightAnchor.constraint(equalToConstant: 50.0),
            chooseRoomToEnterBtn.topAnchor.constraint(equalTo: chooseRoomBtnHolder.topAnchor)

        ])

        createRoomButton.addTarget(self, action: #selector(createChatRoom), for: .touchUpInside)
    }
    
    private func setupEngagementSDK() {
        sdk = EngagementSDK.init(config: EngagementSDKConfig(clientID: clientID))
        EngagementSDK.logLevel = .debug
        sdk.delegate = self
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
    
    @objc private func pauseSession() {
        chatViewController.pause()
    }
    
    @objc private func resumeSession() {
        chatViewController.resume()
    }
    
    @objc private func createChatRoom() {
        sdk.createChatRoom(title: roomTitle.text!.count > 0 ? roomTitle.text : nil) { result in
            switch result {
            case let .success(chatRoomID):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.currentRoomID = chatRoomID
                    self.becomeMemberOfTheRoom()
                    
                    let alert = UIAlertController(
                        title: "Room Created",
                        message: "ID: \(chatRoomID)",
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "Become a member of the new room", style: .default, handler: { _ in
                        self.connectRoom()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Copy Id To Clipboard", style: .default, handler: { _ in
                        UIPasteboard.general.string = chatRoomID
                    }))

                    alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            case let .failure(error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func becomeMemberOfTheRoom() {
        guard let chatRoomID = currentRoomID,
            chatRoomID.count > 0 else {
            showAlert(title: "Enter Room ID", msg: nil)
            return
        }
        sdk.createUserChatRoomMembership(roomID: chatRoomID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.showAlert(title: "Now Member", msg: "")
                case let .failure(error):
                    self.showAlert(title: "Error", msg: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func chooseRoomToEnter() {
        sdk.getUserChatRoomMemberships(page: .first) { result in
            switch result {
            case let .success(chatRooms):
                self.userChatRooms = chatRooms
                self.showChatRoomsWithMembership()
            case let .failure(error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func leaveRoom() {
        if let roomID = currentRoomID {
            sdk.deleteUserChatRoomMembership(roomID: roomID) { result in
                switch result {
                case .success:
                    self.showAlert(title: "Room Left", msg: "id: \(roomID)")
                    self.sdk.getUserChatRoomMemberships(page: .first) { result in
                        switch result {
                        case let .success(chatRooms):
                            self.userChatRooms = chatRooms
                            guard let nextRoom = chatRooms.first else { return }
                            self.currentRoomID = nextRoom.id
                            self.connectRoom()
                        case let .failure(error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func connectRoom() {
        guard let chatRoomID = currentRoomID,
            chatRoomID.count > 0 else {
            showAlert(title: "Enter Room ID", msg: nil)
            return
        }
        let config = ChatSessionConfig(roomID: chatRoomID)
        sdk.connectChatRoom(config: config, completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case let .success(chatSession):
                    self.chatSession = chatSession
                    self.chatViewController.setChatSession(chatSession)
                    self.showAlert(title: "Entered Room ID", msg: chatSession.roomID)
                case let .failure(error):
                    self.showAlert(title: "Error", msg: error.localizedDescription)
                }
            }
        })
    }
    
    private func showChatRoomsWithMembership() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: "Chat Room Memberships",
                message: "Member of \(self.userChatRooms?.count ?? 0) rooms",
                preferredStyle: .actionSheet
            )
            self.userChatRooms?.forEach({ chatRoom in
                alert.addAction(UIAlertAction(title: chatRoom.title ?? "id: \(chatRoom.id)", style: .default, handler: { _ in
                    self.currentRoomID = chatRoom.id
                    self.connectRoom()
                }))
            })
            alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func showAlert(title: String, msg: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: title,
                message: msg ?? "",
                preferredStyle: .alert
            )
        
            alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

}

// MARK: - EngagementSDKDelegate
extension CreateEnterChatRoomUseCase: EngagementSDKDelegate {
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
extension CreateEnterChatRoomUseCase: ContentSessionDelegate {
    func contentSession(_ session: ContentSession, didReceiveWidget widget: WidgetModel) { }
    
    func playheadTimeSource(_ session: ContentSession) -> Date? {
        return nil
    }
    
    func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {
    }
    
    func widget(_ session: ContentSession, didBecomeReady jsonObject: Any) {
       
    }
    
    func widget(_ session: ContentSession, didBecomeReady widget: Widget) {
        
    }
    
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        print("Session status did change \(status)")
    }
    
    func session(_ session: ContentSession, didReceiveError error: Error) {
        print("Did receive error: \(error)")
    }
    
}

// MARK: AccessTokenStorage
extension CreateEnterChatRoomUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
