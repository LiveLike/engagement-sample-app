//
//  ChatInputView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-17.
//

import UIKit
import MobileCoreServices

class ChatInputView: UIView {
    // MARK: Outlets

    @IBOutlet var textField: LLChatInputTextField! {
        didSet {
            textField.delegate = self
            textField.returnKeyType = .send
            textField.isAccessibilityElement = true
            textField.onDeletion = { [weak self] in
                guard let self = self else { return }
                self.textField.accessibilityLabel = ""
                if self.textField.isEmpty == true {
                    self.updateSendButtonVisibility()
                }
            }
        }
    }

    @IBOutlet var keyboardToggleButton: UIButton!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var sendButtonWidth: NSLayoutConstraint!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var inputRootView: UIView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var containerViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewRightConstraint: NSLayoutConstraint!
    
    // MARK: Internal Properties

    weak var delegate: ChatInputViewDelegate?
    var supportExternalImages = false

    // MARK: - View Setup Functions

    func setTheme(_ theme: Theme) {
        textField.font = theme.fontPrimary.maxAccessibilityFontSize(size: 30.0)
        textField.textColor = theme.messageTextColor
        textField.theme = theme
        backgroundView.backgroundColor = theme.chatBodyColor
        inputRootView.layer.cornerRadius = theme.chatCornerRadius
        inputRootView.layer.borderColor = theme.chatInputBorderColor.cgColor
        inputRootView.layer.borderWidth = theme.chatInputBorderWidth
        inputRootView.backgroundColor = theme.chatInputBackgroundColor
        containerViewLeftConstraint.constant = theme.chatInputSideInsets.left
        containerViewRightConstraint.constant = theme.chatInputSideInsets.right
        
        guard let customInputSendButtonImage = theme.chatInputSendButtonImage  else {
            sendButton.setImage(sendButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            if let chatInputSendButtonTint = theme.chatInputSendButtonTint {
                sendButton.tintColor = chatInputSendButtonTint
            }
            log.info("There is no chatInputSendButtonImage set on Theme.")
            return
        }
        
        if let chatInputSendButtonTint = theme.chatInputSendButtonTint {
            sendButton.setImage(customInputSendButtonImage.withRenderingMode(.alwaysTemplate), for: .normal)
            sendButton.tintColor = chatInputSendButtonTint
        } else {
            sendButton.setImage(customInputSendButtonImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }

    func updateSendButtonVisibility() {
        sendButtonHidden(textField.isEmpty == true)
    }

    func reset() {
        textField.text = nil
        textField.imageAttachmentData = nil
        sendButtonHidden(true)
    }

    func sendButtonHidden(_ isHidden: Bool) {
        layoutIfNeeded()
        sendButtonWidth.constant = isHidden ? 0 : 40
        UIView.animate(withDuration: 0.2) {
            self.sendButton.alpha = isHidden ? 0.0 : 1.0
            self.layoutIfNeeded()
        }
    }
    
    /// Overriding default behavior of paste in order to catch custom images from external custom keyboards
    override func paste(_ sender: Any?) {
        
        if UIPasteboard.general.hasStrings {
            if let string = UIPasteboard.general.string {
                insertText(string)
            }
        } else if UIPasteboard.general.hasURLs {
            if let url = UIPasteboard.general.url?.absoluteString {
                insertText(url)
            }
        } else if UIPasteboard.general.hasImages {
            if supportExternalImages {
                if let image = UIPasteboard.general.image {
                    textField.accessibilityLabel = "Image"
                    if let data = UIPasteboard.general.data(forPasteboardType: kUTTypeGIF as String) {
                        textField.imageAttachmentData = data
                    } else {
                        if let data = UIPasteboard.general.data(forPasteboardType: kUTTypeImage as String) {
                            textField.imageAttachmentData = data
                        } else {
                            textField.imageAttachmentData = image.pngData()
                        }
                    }
                }
            } else {
                delegate?.chatInputError(title: "", message: "Images may not be inserted here")
            }
        }
        
        updateSendButtonVisibility()
    }

    // MARK: - Actions

    @IBAction func toggleKeyboardButton() {
        delegate?.chatInputKeyboardToggled()
    }

    func setKeyboardIcon(_ type: KeyboardType) {
        switch type {
        case .standard:
            let image = UIImage(named: "chat_emoji_button", in: Bundle(for: ChatInputView.self), compatibleWith: nil)
            keyboardToggleButton.setImage(image, for: .normal)
        case .sticker:
            let image = UIImage(named: "chat_keyboard_button", in: Bundle(for: ChatInputView.self), compatibleWith: nil)
            keyboardToggleButton.setImage(image, for: .normal)
        }
    }

    @IBAction func sendButtonPressed() {
        textField.accessibilityLabel = ""
        delegate?.chatInputSendPressed(message: ChatInputMessage(
            message: textField.text,
            image: textField.imageAttachmentData))
    }
}

extension ChatInputView: UITextFieldDelegate {
    func insertText(_ text: String) {
        let existingText = textField.text ?? ""
        let range = textField.selectedRange ?? NSRange(location: existingText.count, length: 0)

        if shouldUpdateTextField(text: textField.text, in: range, with: text) {
            if let textRange = textField.selectedTextRange {
                textField.replace(textRange, withText: text)
            } else {
                textField.insertText(text)
            }
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.chatInputBeginEditing(with: textField)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldUpdateTextField(text: textField.text, in: range, with: string)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.chatInputEndEditing(with: textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonPressed()
        return false
    }

    func shouldUpdateTextField(text: String?, in range: NSRange, with string: String) -> Bool {
        
        if textField.imageAttachmentData != nil {
            // if image attached, do not let user input
            if string != "" {
                return false
            }
        }
        
        let characterCountLimit = 150

        // We need to figure out how many characters would be in the string after the change happens
        let startingLength = text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length

        let newLength = startingLength + lengthToAdd - lengthToReplace
        sendButtonHidden(newLength == 0)

        return newLength <= characterCountLimit
    }
}

extension ChatInputView {
    class func instanceFromNib() -> ChatInputView {
        // swiftlint:disable force_cast
        return UINib(nibName: "ChatInputView", bundle: Bundle(for: self)).instantiate(withOwner: nil, options: nil).first as! ChatInputView
    }
}

private extension UITextInput {
    var selectedRange: NSRange? {
        guard let range = selectedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        return NSRange(location: location, length: length)
    }
}

struct ChatInputMessage {
    let message: String?
    let imageURL: URL?
    
    private var imageAttachmentSize: CGSize?
    var imageSize: CGSize? {
        return imageAttachmentSize
    }

    init(message: String?, image: Data?) {
        self.message = message

        if let image = image {
            let imageName = "\(Int64(NSDate().timeIntervalSince1970 * 1000)).gif"
            let fileURL = "mock:\(imageName)"
            Cache.shared.set(object: image, key: fileURL, completion: nil)
            self.imageURL = URL(string: fileURL)
            
            if let tempImage = UIImage.decode(image) {
                self.imageAttachmentSize = tempImage.size
            }
            
        } else {
            self.imageURL = nil
        }
    }
    
    var isEmpty: Bool {
        if let message = message?.trimmingCharacters(in: .whitespaces), !message.isEmpty {
            return false
        }

        if imageURL != nil {
            return false
        }

        return true
    }
}

protocol ChatInputViewDelegate: AnyObject {
    func chatInputSendPressed(message: ChatInputMessage)
    func chatInputKeyboardToggled()
    func chatInputBeginEditing(with textField: UITextField)
    func chatInputEndEditing(with textField: UITextField)
    func chatInputError(title: String, message: String)
}
