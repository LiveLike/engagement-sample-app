//
//  ViewController.swift
//  Sample App
//
//  Created by Jelzon WORK on 4/3/20.
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class HomeViewController: UIViewController {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let clientIDLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Client ID"
        label.textAlignment = .left
        return label
    }()
    
    private let clientIDTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter Client ID"
        return textField
    }()
    
    private let programIDLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Program ID"
        label.textAlignment = .left
        return label
    }()
    
    private let programIDTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter Program ID"
        return textField
    }()
    
    private let useCasesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Use Cases"
        label.textAlignment = .left
        return label
    }()
    
    private let widgetModuleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Widgets", for: .normal)
        button.backgroundColor = .systemGray6
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(didPressWidgetButton), for: .touchUpInside)
        return button
    }()
    
    private let chatWidgetModuleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Chat & Widgets", for: .normal)
        button.backgroundColor = .systemGray6
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(didPressChatButton), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Engagement SDK \(EngagementSDK.version)"
    
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        stackView.addArrangedSubview(clientIDLabel)
        stackView.addArrangedSubview(clientIDTextField)
        stackView.addArrangedSubview(programIDLabel)
        stackView.addArrangedSubview(programIDTextField)
        stackView.addArrangedSubview(useCasesLabel)
        stackView.addArrangedSubview(widgetModuleButton)
        stackView.addArrangedSubview(chatWidgetModuleButton)
        
        clientIDTextField.addTarget(self, action: #selector(clientIDTextFieldEditingDidEnd), for: .editingDidEnd)
        programIDTextField.addTarget(self, action: #selector(programIDTextFieldEditingDidEnd), for: .editingDidEnd)
        
        
        // Loads previous client id and program id from UserDefaults
        clientIDTextField.text = Defaults.activeClientID
        programIDTextField.text = Defaults.activeProgramID
    }
    
    @objc private func clientIDTextFieldEditingDidEnd() {
        // Stores clientID into UserDefaults if not nil or empty
        guard let clientID = clientIDTextField.text, !clientID.isEmpty else {
            return
        }
        Defaults.activeClientID = clientID
    }

    @objc private func programIDTextFieldEditingDidEnd() {
        // Stores programID into UserDefaults if not nil or empty
        guard let programID = programIDTextField.text, !programID.isEmpty else {
            return
        }
        Defaults.activeProgramID = programID
    }
    
    @objc func didPressWidgetButton() {
        guard let clientID = Defaults.activeClientID,
            let programID = Defaults.activeProgramID else {
                displayCliendProgramIDError()
                return
        }
        
        let widgetsVC = WidgetsUseCase(clientID: clientID, programID: programID)
        widgetsVC.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(widgetsVC, animated: true)
    }
    
    @objc func didPressChatButton() {
        guard let clientID = Defaults.activeClientID,
            let programID = Defaults.activeProgramID else {
                displayCliendProgramIDError()
                return
        }
        
        let chatWidgetsVC = ChatWidgetsViewController(clientID: clientID, programID: programID)
        chatWidgetsVC.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(chatWidgetsVC, animated: true)
    }
    
    private func displayCliendProgramIDError() {
        let alertController = UIAlertController(title: "Error!",
                                                message: "Please enter a valid Client ID and Program ID",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .default,
                                                handler: { [weak alertController] _ in
            alertController?.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }

}

