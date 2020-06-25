//
//  ChatViewController+Input.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-06-27.
//

import UIKit

extension ChatViewController {
    // MARK: Input views

    private func updateInputView(_ inputView: UIView?, keyboardType: KeyboardType) {
        chatInputViewAccessory.setKeyboardIcon(keyboardType)

        if chatInputViewAccessory.textField.isFirstResponder {
            chatInputViewAccessory.textField.resignFirstResponder()
            chatInputViewAccessory.textField.inputView = inputView
            chatInputViewAccessory.textField.becomeFirstResponder()
        } else {
            chatInputViewAccessory.textField.inputView = inputView
        }
    }

    func resetInputViews() {
        chatInputViewAccessory.reset()
    }

    // MARK: Keyboard input types

    func updateKeyboardType(_ type: KeyboardType, isReset: Bool) {
        keyboardType = type
        switch type {
        case .standard:
            updateInputView(nil, keyboardType: keyboardType)
        case .sticker:
            self.updateInputView(self.stickerInputView, keyboardType: self.keyboardType)
        }
        if !isReset {
            eventRecorder?.record(.keyboardSelected(properties: keyboardType))
        }
    }

    // handles a scenario where many sticker packs exist with zero stickers
    func doStickersExist(stickerPacks: [StickerPack]) -> Bool {
        return stickerPacks.first(where: { $0.stickers.count > 0 }) != nil
    }
    
    var recentlyUsedStickerPacks: [StickerPack] {
        guard let chatSession = chatSession else { return [] }
        return StickerPack.recentStickerPacks(from: Array(chatSession.recentlyUsedStickers))
    }
}

extension ChatViewController: ChatInputViewDelegate {
    func chatInputError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    func chatInputBeginEditing(with textField: UITextField) {
        if !keyboardIsVisible, keyboardType == .standard {
            eventRecorder?.record(.keyboardSelected(properties: keyboardType))
        }
    }

    func chatInputEndEditing(with textField: UITextField) {}

    func chatInputSendPressed(message: ChatInputMessage) {
        if !message.isEmpty {
            sendMessage(message)
        } else {
            if keyboardIsVisible {
                let keyboardProperties = KeyboardHiddenProperties(keyboardType: keyboardType, keyboardHideMethod: .emptySend, messageID: nil)
                eventRecorder?.record(.keyboardHidden(properties: keyboardProperties))
            }
        }
        resetInputViews()
    }

    func chatInputKeyboardToggled() {
        if !chatInputViewAccessory.textField.isFirstResponder {
            chatInputViewAccessory.textField.becomeFirstResponder()
        }

        switch keyboardType {
        case .standard:
            updateKeyboardType(.sticker, isReset: false)
        case .sticker:
            updateKeyboardType(.standard, isReset: false)
        }
    }
}

extension ChatViewController: StickerInputViewDelegate {
    func stickerSelected(_ sticker: Sticker) {
        chatInputViewAccessory.insertText(":\(sticker.shortcode):")
        
        guard let chatSession = chatSession else { return }
        chatSession.recentlyUsedStickers.insert(sticker, at: 0)
        self.stickerInputView.stickerPacks = self.recentlyUsedStickerPacks + stickerPacks
    }

    func backspacePressed() {
        chatInputViewAccessory.textField.deleteBackward()
    }
}
