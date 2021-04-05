//
//  ChatInputView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-17.
//

import UIKit
import MobileCoreServices

public class ChatInputView: UIView {
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

    /// Determines whether the user is able to post images into chat
    public var supportExternalImages = true
    private var keyboardType: KeyboardType = .standard
    private var keyboardIsVisible = false

    lazy var stickerInputView: StickerInputView = {
        let stickerInputView = StickerInputView.instanceFromNib()
        stickerInputView.delegate = self
        return stickerInputView
    }()

    private var chatSession: InternalChatSessionProtocol?

    private var stickerPacks: [StickerPack] = []

    private var theme: Theme = Theme()

    private var recentlyUsedStickerPacks: [StickerPack] {
        guard let chatSession = chatSession else { return [] }
        return StickerPack.recentStickerPacks(from: Array(chatSession.recentlyUsedStickers))
    }

    private var keyboardDidShowNotificationToken: NSObjectProtocol?
    private var keyboardDidHideNotificationToken: NSObjectProtocol?

    public override func awakeFromNib() {
        super.awakeFromNib()

        keyboardDidShowNotificationToken = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.keyboardIsVisible = true
        }

        keyboardDidHideNotificationToken = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.keyboardIsVisible = false
        }

        setTheme(self.theme)
    }

    deinit {
        NotificationCenter.default.removeObserver(keyboardDidShowNotificationToken!)
        NotificationCenter.default.removeObserver(keyboardDidHideNotificationToken!)
    }

    // MARK: - View Setup Functions

    func setTheme(_ theme: Theme) {
        self.theme = theme
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

        stickerInputView.setTheme(theme)
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
    public override func paste(_ sender: Any?) {
        
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

    public func setChatSession(_ chatSession: ChatSession) {
        self.clearChatSession()

        guard let chatSession = chatSession as? InternalChatSessionProtocol else { return }
        self.chatSession = chatSession

        chatSession.stickerRepository.getStickerPacks { [weak self] result in
            guard let self = self else { return}

            DispatchQueue.main.async {
                switch result {
                case .success(let stickerPacks):
                    self.stickerPacks = stickerPacks
                case .failure(let error):
                    log.error("Failed to get sticker packs with error: \(error)")
                }

                self.stickerInputView.stickerPacks = self.recentlyUsedStickerPacks + self.stickerPacks
                self.keyboardToggleButton.setImage(self.theme.chatStickerKeyboardIcon, for: .normal)
                self.keyboardToggleButton.setImage(self.theme.chatStickerKeyboardIconSelected, for: .selected)
                self.keyboardToggleButton.tintColor = self.theme.chatStickerKeyboardIconTint
                self.keyboardToggleButton.isSelected = false
                self.keyboardToggleButton.isHidden = !self.doStickersExist(stickerPacks: self.stickerPacks)
            }
        }
    }

    public func clearChatSession() {
        self.chatSession = nil
    }

    public func setContentSession(_ contentSession: ContentSession) {
        guard let contentSession = contentSession as? InternalContentSession else { return }

        contentSession.getChatSession { [weak self] result in
            switch result {
            case .success(let chatSession):
                self?.setChatSession(chatSession)
            case .failure(let error):
                log.error(error)
            }
        }
    }

    public func clearContentSession() {
        self.chatSession = nil
    }

    // handles a scenario where many sticker packs exist with zero stickers
    func doStickersExist(stickerPacks: [StickerPack]) -> Bool {
        return stickerPacks.first(where: { $0.stickers.count > 0 }) != nil
    }

    // MARK: - Actions

    @IBAction func toggleKeyboardButton() {
        chatInputKeyboardToggled()
    }

    func chatInputKeyboardToggled() {
        if !textField.isFirstResponder {
            textField.becomeFirstResponder()
        }

        switch keyboardType {
        case .standard:
            updateKeyboardType(.sticker, isReset: false)
        case .sticker:
            updateKeyboardType(.standard, isReset: false)
        }
    }

    func updateKeyboardType(_ type: KeyboardType, isReset: Bool) {
        keyboardType = type
        switch type {
        case .standard:
            updateInputView(nil, keyboardType: keyboardType)
        case .sticker:
            self.updateInputView(self.stickerInputView, keyboardType: self.keyboardType)
        }
        if !isReset {
            chatSession?.eventRecorder.record(.keyboardSelected(properties: keyboardType))
        }
    }

    private func updateInputView(_ inputView: UIView?, keyboardType: KeyboardType) {
        setKeyboardIcon(keyboardType)

        if textField.isFirstResponder {
            textField.resignFirstResponder()
            textField.inputView = inputView
            textField.becomeFirstResponder()
        } else {
            textField.inputView = inputView
        }
    }

    func setKeyboardIcon(_ type: KeyboardType) {
        switch type {
        case .standard:
            keyboardToggleButton.isSelected = false
            keyboardToggleButton.tintColor = theme.chatStickerKeyboardIconTint
        case .sticker:
            keyboardToggleButton.isSelected = true
            keyboardToggleButton.tintColor = theme.chatStickerKeyboardIconSelectedTint
        }
    }

    @IBAction func sendButtonPressed() {
        textField.accessibilityLabel = ""
        
        let newChatMessage: NewChatMessage? = {
            if let inputFieldText = textField.text, !inputFieldText.isEmpty {
                return NewChatMessage(text: inputFieldText)
            } else if let imageData = textField.imageAttachmentData {
                let imageSize = UIImage.decode(imageData)?.size ?? CGSize(width: 100, height: 100)
                return NewChatMessage(imageData: imageData, imageSize: imageSize)
            } else {
                return nil
            }
        }()
        
        if let newChatMessage = newChatMessage {
            delegate?.chatInputSendPressed(message: newChatMessage)
            sendMessage(newChatMessage)
        } else {
            if keyboardIsVisible {
                let keyboardProperties = KeyboardHiddenProperties(keyboardType: keyboardType, keyboardHideMethod: .emptySend, messageID: nil)
                chatSession?.eventRecorder.record(.keyboardHidden(properties: keyboardProperties))
            }
        }
        reset()
    }

    func sendMessage(_ message: NewChatMessage) {
        guard let chatSession = chatSession else {
            return
        }
        
        let newMessage = chatSession.sendMessage(message) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let chatMessage):
                log.info("Chat Message ID: \(chatMessage.id) successfuly sent")
            case .failure(let error):
                log.error(error.localizedDescription)
                if error.localizedDescription == PubNubChannelError.sendMessageFailedAccessDenied.errorDescription {
                    self.delegate?.chatInputError(title: "", message: "EngagementSDK.chat.error.sendMessageFailedAccessDenied".localized())
                }
            }
        }
        
        // Report Analytics
        let keyboardProperties = KeyboardHiddenProperties(keyboardType: self.keyboardType, keyboardHideMethod: .messageSent, messageID: newMessage.id.asString)
        chatSession.eventRecorder.record(.keyboardHidden(properties: keyboardProperties))
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

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.chatInputBeginEditing(with: textField)
        if !keyboardIsVisible, keyboardType == .standard {
            chatSession?.eventRecorder.record(.keyboardSelected(properties: keyboardType))
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldUpdateTextField(text: textField.text, in: range, with: string)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.chatInputEndEditing(with: textField)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
    public class func instanceFromNib() -> ChatInputView {
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

protocol ChatInputViewDelegate: AnyObject {
    func chatInputSendPressed(message: NewChatMessage)
    func chatInputKeyboardToggled()
    func chatInputBeginEditing(with textField: UITextField)
    func chatInputEndEditing(with textField: UITextField)
    func chatInputError(title: String, message: String)
}

extension ChatInputView: StickerInputViewDelegate {
    func stickerSelected(_ sticker: Sticker) {
        insertText(":\(sticker.shortcode):")

        guard let chatSession = chatSession else { return }
        chatSession.recentlyUsedStickers.insert(sticker, at: 0)
        self.stickerInputView.stickerPacks = self.recentlyUsedStickerPacks + stickerPacks
    }

    func backspacePressed() {
        textField.deleteBackward()
    }
}
