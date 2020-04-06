//
//  ViewController.swift
//  Sample App
//
//  Created by Jelzon WORK on 4/3/20.
//  Copyright © 2020 LiveLike. All rights reserved.
//

import UIKit
import EngagementSDK

class ViewController: UIViewController {
    
    private let clientIDUserDefaultsKey = "com.livelike.SampleApp.clientID"
    private let programIDUserDefaultsKey = "com.livelike.SampleApp.programID"
    
    private let userDefaults = UserDefaults.standard
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let sdkVersionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "LL SDK [\(EngagementSDK.version)]"
        label.textAlignment = .center
        return label
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        stackView.addArrangedSubview(sdkVersionLabel)
        stackView.addArrangedSubview(clientIDLabel)
        stackView.addArrangedSubview(clientIDTextField)
        stackView.addArrangedSubview(programIDLabel)
        stackView.addArrangedSubview(programIDTextField)
        stackView.addArrangedSubview(useCasesLabel)
        
        clientIDTextField.addTarget(self, action: #selector(clientIDTextFieldEditingDidEnd), for: .editingDidEnd)
        programIDTextField.addTarget(self, action: #selector(programIDTextFieldEditingDidEnd), for: .editingDidEnd)
        
        
        // Loads previous client id and program id from UserDefaults
        clientIDTextField.text = userDefaults.string(forKey: clientIDUserDefaultsKey)
        programIDTextField.text = userDefaults.string(forKey: programIDUserDefaultsKey)
    }
    
    @objc private func clientIDTextFieldEditingDidEnd() {
        // Stores clientID into UserDefaults if not nil or empty
        guard let clientID = clientIDTextField.text, !clientID.isEmpty else {
            return
        }
        userDefaults.set(clientID, forKey: clientIDUserDefaultsKey)
    }

    @objc private func programIDTextFieldEditingDidEnd() {
        // Stores programID into UserDefaults if not nil or empty
        guard let programID = programIDTextField.text, !programID.isEmpty else {
            return
        }
        userDefaults.set(programID, forKey: clientIDUserDefaultsKey)
    }

}

