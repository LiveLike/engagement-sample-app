//
//  ChatViewController+Input.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-27.
//

import UIKit

extension ChatViewController: ChatInputViewDelegate {
    func chatInputError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    func chatInputBeginEditing(with textField: UITextField) { }
    func chatInputEndEditing(with textField: UITextField) {}
    func chatInputSendPressed(message: ChatInputMessage) { }
    func chatInputKeyboardToggled() { }
}
