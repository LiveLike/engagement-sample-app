//
//  PrivateChatViewController.swift
//  Sample App
//
//  Created by Jelzon Monzon on 3/22/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

@available(iOS 13.0, *)
class PrivateChatViewController: UIViewController {
    
    private let chatSession: ChatSession
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()
    
    private let chatInputView: ChatInputView = {
        let chatInputView = ChatInputView.instanceFromNib()
        chatInputView.translatesAutoresizingMaskIntoConstraints = false
        return chatInputView
    }()
    
    init(chatSession: ChatSession) {
        self.chatSession = chatSession
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.addSubview(chatInputView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.90),
            
            chatInputView.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            chatInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatInputView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])
        
        chatSession.addDelegate(self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MyChatMessageCell.self, forCellReuseIdentifier: "myChatCell")
        tableView.register(UserChatMessageCell.self, forCellReuseIdentifier: "userChatCell")
        chatInputView.setChatSession(chatSession)
    }
    
}

@available(iOS 13.0, *)
extension PrivateChatViewController: ChatSessionDelegate {
    func chatSession(_ chatSession: ChatSession, didRecieveNewMessage message: ChatMessage) {
        self.tableView.reloadData()
    }
}

@available(iOS 13.0, *)
extension PrivateChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatSession.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let chatMessage = self.chatSession.messages[indexPath.row]
        if chatMessage.isMine {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myChatCell") as! MyChatMessageCell
            cell.configure(chatMessage)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userChatCell") as! UserChatMessageCell
            cell.configure(chatMessage)
            return cell
        }
    }
}

@available(iOS 13.0, *)
extension PrivateChatViewController: UITableViewDelegate { }

@available(iOS 13.0, *)
class MyChatMessageCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textColor = .systemGray6
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.6),
            
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ chatMessage: ChatMessage) {
        label.text = chatMessage.text
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
}

@available(iOS 13.0, *)
class UserChatMessageCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 6
        return view
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(nicknameLabel)
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.6),
            
            nicknameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nicknameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            nicknameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            nicknameLabel.bottomAnchor.constraint(equalTo: label.topAnchor),
            
            label.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ chatMessage: ChatMessage) {
        nicknameLabel.text = chatMessage.senderNickname
        label.text = chatMessage.text
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nicknameLabel.text = nil
        label.text = nil
    }
}
