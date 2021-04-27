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
    
    private var chatSession: ChatSession!
    private let sdk: EngagementSDK
    private let contentSession: ContentSession
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()
    
    private let quickMessageButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Quick Replies", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.isUserInteractionEnabled = false
        button.alpha = 0.0
        return button
    }()
    
    private var isLoading: Bool = true
    
    init(clientID: String, programID: String) {
        self.sdk = EngagementSDK(config: EngagementSDKConfig(clientID: clientID))
        self.contentSession = sdk.contentSession(config: SessionConfiguration(programID: programID))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(quickMessageButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.90),
            
            quickMessageButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 10),
            quickMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            quickMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            quickMessageButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -10)
        ])
        
        tableView.register(MyTextMessageCell.self, forCellReuseIdentifier: "myTextCell")
        tableView.register(MyImageMessageCell.self, forCellReuseIdentifier: "myImageCell")
        tableView.register(UserTextMessageCell.self, forCellReuseIdentifier: "userTextCell")
        tableView.register(UserImageMessageCell.self, forCellReuseIdentifier: "userImageCell")
        quickMessageButton.addTarget(self, action: #selector(sendCustomMessage), for: .touchUpInside)
        self.contentSession.getChatSession { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatSession):
                self.chatSession = chatSession
                chatSession.addDelegate(self)
                self.tableView.dataSource = self
                self.tableView.delegate = self
                
                // Starts table at bottom
                DispatchQueue.main.async {
                    self.quickMessageButton.isUserInteractionEnabled = true
                    self.quickMessageButton.alpha = 1.0
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(
                        at: IndexPath(row: self.chatSession.messages.count - 1, section: 0),
                        at: .bottom,
                        animated: false
                    )
                    self.isLoading = false
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    @objc func sendCustomMessage() {
        let alert = UIAlertController(
            title: "Pick a Quick Message!",
            message: "",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "\"Cool!\"", style: .default, handler: { _ in
            let chatMessage = NewChatMessage(text: "Cool!")
            self.chatSession.sendMessage(chatMessage) { _ in }
        }))
        
        alert.addAction(UIAlertAction(title: "\"Boooooooo!\"", style: .default, handler: { _ in
            let chatMessage = NewChatMessage(text: "Boooooooo!")
            self.chatSession.sendMessage(chatMessage) { _ in }
        }))
        
        alert.addAction(UIAlertAction(title: "\"Wow!\"", style: .default, handler: { _ in
            let chatMessage = NewChatMessage(text: "Wow!")
            self.chatSession.sendMessage(chatMessage) { _ in }
        }))
        
        alert.addAction(UIAlertAction(title: "\"Really?\"", style: .default, handler: { _ in
            let chatMessage = NewChatMessage(text: "Really?")
            self.chatSession.sendMessage(chatMessage) { _ in }
        }))

        alert.addAction(UIAlertAction(title: "Chimpanzee", style: .default, handler: { _ in
            guard let imageURL = URL(string: "https://media.giphy.com/media/l1KVboXQeiaX7FHgI/giphy.gif") else { return }
            let chatMessage = NewChatMessage(
                imageURL: imageURL,
                imageSize: CGSize(width: 100, height: 100)
            )
            self.chatSession.sendMessage(chatMessage) { _ in }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

@available(iOS 13.0, *)
extension PrivateChatViewController: ChatSessionDelegate {
    func chatSession(_ chatSession: ChatSession, didRecieveNewMessage message: ChatMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.insertRows(
                at: [IndexPath(row: chatSession.messages.count - 1, section: 0)],
                with: .none
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.tableView.scrollToRow(
                    at: IndexPath(row: chatSession.messages.count - 1, section: 0),
                    at: .bottom,
                    animated: true
                )
            }
            
        }   
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
            if chatMessage.imageURL != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "myImageCell") as! MyImageMessageCell
                cell.configure(chatMessage)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "myTextCell") as! MyTextMessageCell
                cell.configure(chatMessage)
                return cell
            }
        } else {
            if chatMessage.imageURL != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "userImageCell") as! UserImageMessageCell
                cell.configure(chatMessage)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "userTextCell") as! UserTextMessageCell
                cell.configure(chatMessage)
                return cell
            }
        }
            
    }
}

@available(iOS 13.0, *)
extension PrivateChatViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        if offsetY < 0, !isLoading {
            self.isLoading = true
            self.tableView.tableHeaderView = createLoadingFooterView()
            // Show loading spinner for at least 1 second for smooth user experience
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                self.chatSession.loadNextHistory { result in
                    DispatchQueue.main.async {
                        switch result {
                        case let .success(messages):
                            // Inserting rows in place by insertRows from 0 to messages.count
                            // Then scrolling back to first visible message before the insertRows happened.
                            
                            let indexPaths = messages.enumerated().map { index, _ in
                                return IndexPath(row: index, section: 0)
                            }
                            UIView.setAnimationsEnabled(false)
                            self.tableView.insertRows(at: indexPaths, with: .none)
                            UIView.setAnimationsEnabled(true)
                            
                            let currentRowAfterInsert = messages.count - 1
                            if currentRowAfterInsert < self.tableView.numberOfRows(inSection: 0) && currentRowAfterInsert >= 0 {
                                // scroll back to the position we were in before insertion
                                self.tableView.scrollToRow(
                                    at: IndexPath(row: currentRowAfterInsert, section: 0),
                                    at: .top,
                                    animated: false
                                )
                            }
                        case let .failure(error):
                            print(error)
                        }
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func createLoadingFooterView() -> UIView {
        let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        let spinner = UIActivityIndicatorView()
        spinner.center = loadingView.center
        loadingView.addSubview(spinner)
        spinner.startAnimating()
        
        return loadingView
    }
}

@available(iOS 13.0, *)
class MyTextMessageCell: UITableViewCell {
    
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
class MyImageMessageCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var imageDataTask: URLSessionDataTask?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(messageImageView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.6),
            
            messageImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            messageImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            messageImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            messageImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ chatMessage: ChatMessage) {
        guard let imageURL = chatMessage.imageURL else { return }
        let imageSize = chatMessage.imageSize ?? CGSize(width: 200, height: 200)
        
        NSLayoutConstraint.activate([
            messageImageView.heightAnchor.constraint(equalToConstant: imageSize.height),
            messageImageView.widthAnchor.constraint(equalToConstant: imageSize.width)
        ])
        
        self.imageDataTask = URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
            guard let self = self else { return }
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.messageImageView.image = UIImage(data: data)
            }
        }
        self.imageDataTask?.resume()

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageDataTask?.cancel()
        imageDataTask = nil
        messageImageView.image = nil
    }
}

@available(iOS 13.0, *)
class UserTextMessageCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
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

@available(iOS 13.0, *)
class UserImageMessageCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var imageDataTask: URLSessionDataTask?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(nicknameLabel)
        containerView.addSubview(messageImageView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.6),
            
            nicknameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nicknameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            nicknameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            nicknameLabel.bottomAnchor.constraint(equalTo: messageImageView.topAnchor),
            
            messageImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            messageImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            messageImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            messageImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ chatMessage: ChatMessage) {
        guard let imageURL = chatMessage.imageURL else { return }
        let imageSize = chatMessage.imageSize ?? CGSize(width: 200, height: 200)
        
        NSLayoutConstraint.activate([
            messageImageView.heightAnchor.constraint(equalToConstant: imageSize.height),
            messageImageView.widthAnchor.constraint(equalToConstant: imageSize.width)
        ])
        
        self.imageDataTask = URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
            guard let self = self else { return }
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.messageImageView.image = UIImage(data: data)
            }
        }
        self.imageDataTask?.resume()

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageDataTask?.cancel()
        imageDataTask = nil
        nicknameLabel.text = nil
        messageImageView.image = nil
    }
}
