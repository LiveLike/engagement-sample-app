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
    private var safeArea: UILayoutGuide {
        get {
            if #available(iOS 11.0, *) {
                return self.view.safeAreaLayoutGuide
            } else {
                return self.view.layoutMarginsGuide
            }
        }
    }
    
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
        textField.addTarget(self, action: #selector(clientIDTextFieldEditingDidEnd), for: .editingDidEnd)
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
        textField.addTarget(self, action: #selector(programIDTextFieldEditingDidEnd), for: .editingDidEnd)
        return textField
    }()
    
    private let useCasesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Use Cases"
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.textAlignment = .left
        return label
    }()
    
    private let chatModuleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Chat", for: .normal)
        button.backgroundColor = .lightGray
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(chatModuleButtonSelected), for: .touchUpInside)
        return button
    }()
    
    private let widgetModuleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Widgets", for: .normal)
        button.backgroundColor = .lightGray
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(widgetModuleButtonSelected), for: .touchUpInside)
        return button
    }()
    
    private let widgetChatSpoilerPreventionModule: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Widgets, Chat and Spoiler Prevention", for: .normal)
        button.backgroundColor = .lightGray
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(chatAndWidgetModuleButtonSelected), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Engagement SDK \(EngagementSDK.version)"
    
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -10)
        ])
        
        stackView.addArrangedSubview(clientIDLabel)
        stackView.addArrangedSubview(clientIDTextField)
        stackView.addArrangedSubview(programIDLabel)
        stackView.addArrangedSubview(programIDTextField)
        stackView.addArrangedSubview(UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 50)))
        stackView.addArrangedSubview(useCasesLabel)
        stackView.addArrangedSubview(chatModuleButton)
        stackView.addArrangedSubview(widgetModuleButton)
        stackView.addArrangedSubview(widgetChatSpoilerPreventionModule)
        
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
    
    @objc func widgetModuleButtonSelected() {
        guard let clientID = Defaults.activeClientID, !clientID.isEmpty else {
            presentInvalidClientIDAlert()
            return
        }
        
        guard let programID = Defaults.activeProgramID, !programID.isEmpty else {
            presentInvalidProgramIDAlert()
            return
        }
        
        let widgetsVC = WidgetsUseCase(clientID: clientID, programID: programID)
        widgetsVC.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(widgetsVC, animated: true)
    }
    
    @objc func chatAndWidgetModuleButtonSelected() {
        guard let clientID = Defaults.activeClientID, !clientID.isEmpty else {
            presentInvalidClientIDAlert()
            return
        }
        
        guard let programID = Defaults.activeProgramID, !programID.isEmpty else {
            presentInvalidProgramIDAlert()
            return
        }
        
        let widgetChatSpoilerPreventionUseCase = WidgetChatSpoilerPreventionUseCase(clientID: clientID,
                                                                                    programID: programID)
        
        widgetChatSpoilerPreventionUseCase.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(widgetChatSpoilerPreventionUseCase, animated: true)
    }
    
    @objc public func chatModuleButtonSelected() {
        guard let clientID = Defaults.activeClientID, !clientID.isEmpty else {
            presentInvalidClientIDAlert()
            return
        }
        
        guard let programID = Defaults.activeProgramID, !programID.isEmpty else {
            presentInvalidProgramIDAlert()
            return
        }
        
        let chatModule = ChatUseCase(clientID: clientID, programID: programID)
        navigationController?.pushViewController(chatModule, animated: true)
    }
    
    private func presentInvalidClientIDAlert() {
        let alert = UIAlertController(
            title: "Invalid Client ID",
            message: "Set a Client ID before selecting a Use Case.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func presentInvalidProgramIDAlert() {
        let alert = UIAlertController(
            title: "Invalid Program ID",
            message: "Set a Program ID before selecting a Use Case.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

