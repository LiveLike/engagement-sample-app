//
//  TokenGatedChatUseCase.swift
//  Sample App
//
//  Created by Mike Moloksher on 5/12/22.
//  Copyright © 2022 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK
import WalletConnectSwift

class TokenGatedChatUseCase: UIViewController {
    
    private var sdk: EngagementSDK!
    private let clientID: String
    private var walletConnect: WalletConnect!
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20.0
        return stackView
    }()
    
    private let chatroomIDTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter Chat Room ID"
        return textField
    }()
    
    private let enterChatroomBTN: UIButton = {
        let button = UIButton()
        button.titleLabel?.textColor = .black
        button.backgroundColor = .darkGray
        button.setTitle("Enter Chat Room", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private let connectWalletBTN: UIButton = {
        let button = UIButton()
        button.titleLabel?.textColor = .black
        button.backgroundColor = .gray
        button.setTitle("Connect Wallet", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()

    init(
        clientID: String
    ) {
        self.clientID = clientID
        super.init(nibName: nil, bundle: nil)
        self.title = "Chat Token Gating Use Case"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()

        sdk = EngagementSDK.init(config: EngagementSDKConfig(clientID: clientID))
        sdk.delegate = self
        
        connectWalletBTN.addTarget(self, action: #selector(connectWallet(_:)), for: .touchUpInside)
        enterChatroomBTN.addTarget(self, action: #selector(enterChatroom(_:)), for: .touchUpInside)
        walletConnect = WalletConnect(delegate: self)
        walletConnect.reconnectIfNeeded()
        
        if let _ = Defaults.walletAddress {
            connectWalletBTN.setTitle("Wallet Connected", for: .normal)
            stackView.addArrangedSubview(chatroomIDTextField)
            stackView.addArrangedSubview(enterChatroomBTN)
        } else {
            connectWalletBTN.setTitle("Connect Wallet", for: .normal)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
        
        stackView.addArrangedSubview(connectWalletBTN)
    }
    
    /// Connect to a `ChatSession` and attach it to a `ChatViewController`
    /// to let the user into a chatroom
    private func connectToTokenGatedChatroom() {
        guard let chatroomID = chatroomIDTextField.text else { return }
        
        sdk.connectChatRoom(
            config: ChatSessionConfig(roomID: chatroomID)
        ) { result in
                
            switch result {
            case .failure(let error):
                print(error)
            case .success(let chatSession):
                DispatchQueue.main.async {
                    let chatViewController = ChatViewController()
                    chatViewController.setChatSession(chatSession)
                    self.navigationController?.pushViewController(chatViewController, animated: true)
                }
            }
        }
    }
    
    /// When Enter Chat Room button is pressed
    @objc private func enterChatroom(_ sender: Any) {
        guard let chatroomID = chatroomIDTextField.text else { return }
            
        // 1. Retrieve token gate information from a specific chatroom
        sdk.getChatRoomInfo(
            roomID: chatroomID
        ) { result in
            
            switch result {
            case .failure(let error):
                print(error)
            case .success(let chatroomInfo):
                
                // 2. If token gates enabled on the chatroom, retrieve the smart contract address
                // NOTE: for simplicity we are only using the first token gate available
                if let firstTokenGatedAddress = chatroomInfo.tokenGates.first {
                    
                    // Create an Etherscan account to receive and API key
                    // https://docs.etherscan.io/getting-started/viewing-api-usage-statistics#creating-an-api-key
                    let etherscan = EtherscanAPI(
                        ethNetwork: .ropsten,
                        apiKey: "<API KEY>"
                    )
                    
                    // 3.Use Etherscan API to see if connected wallet & smart contract address
                    // have a token balance
                    // https://docs.etherscan.io/api-endpoints/tokens#get-erc20-token-account-balance-for-tokencontractaddress
                    etherscan.getERC20TokenBalance(
                        walletAddress: Defaults.walletAddress!,
                        contractAddress: firstTokenGatedAddress.contractAddress
                    ) { result in
                        
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let etherscanResult):
                            
                            // 4. If the token balance is not 0, then the token exists in the
                            // connected wallet
                            if etherscanResult.result != "0" {
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    
                                    // 5. Let the user into the chatroom
                                    self.connectToTokenGatedChatroom()
                                }
                            } else {
                                print("No valid tokens found in the user's wallet")
                                
                                let alert = UIAlertController(
                                    title: "Chat Token Gate",
                                    message: "No valid tokens found in the connected wallet",
                                    preferredStyle: .alert
                                )
                                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                } else {
                    print("Chatroom Does not have any Token Gates")
                    self.connectToTokenGatedChatroom()
                }
            }
        }
    }
    
    /// Utilized the WalletConnectSwift framework to connect a wallet on the user's device
    @objc private func connectWallet(_ sender: Any) {
        if let _ = Defaults.walletAddress {
            connectWalletBTN.setTitle("Wallet Connected", for: .normal)
        } else {
            let connectionUrl = walletConnect.connect()

            /// https://docs.walletconnect.org/mobile-linking#for-ios
            /// **NOTE**: Majority of wallets support universal links that you should normally use in production application
            /// Here deep link provided for integration with server test app only
            let deepLinkUrl = "wc://wc?uri=\(connectionUrl)"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let url = URL(string: deepLinkUrl), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                   print("Error: Not able to open deep link to connet a wallet")
                }
            }
        }
    }
}

extension TokenGatedChatUseCase: EngagementSDKDelegate {
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

extension TokenGatedChatUseCase: WalletConnectDelegate {
    func failedToConnect() {
        print("Failed to connect to a wallet")
    }

    func didConnect() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let _ = Defaults.walletAddress {
                self.connectWalletBTN.setTitle("Wallet Connected", for: .normal)
                self.stackView.addArrangedSubview(self.chatroomIDTextField)
                self.stackView.addArrangedSubview(self.enterChatroomBTN)
            } else {
                print("Failed to retrieve wallet address")
            }
        }
    }

    func didDisconnect() {
        print("Wallet Disconnected")
    }
}
