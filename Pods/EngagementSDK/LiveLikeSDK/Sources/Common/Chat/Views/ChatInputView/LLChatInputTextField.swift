//
//  LLChatInputTextField.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 1/8/20.
//

import UIKit

class LLChatInputTextField: UITextField {
    
    private let placeholderText = "EngagementSDK.chat.input.placeholder".localized(comment: "Placeholder text used in chat message input field")
    
    var imageAttachmentData: Data? {
        didSet {
            toggleImageMode(imageData: imageAttachmentData)
        }
    }
    
    var theme: Theme = Theme() {
        didSet {
            updatePlaceholderText(with: placeholderText,
                                  theme: theme)
        }
    }
    
    var isEmpty: Bool {
        if let text = self.text {
            if text.isEmpty && imageAttachmentData == nil {
                return true
            }
        }
        return false
    }
    
    var onDeletion: (() -> Void)?
    
    override func deleteBackward() {
        if text == "" {
            imageAttachmentData = nil
        }
        
        onDeletion?()
        
        super.deleteBackward()
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        // Fixes the issue where placeholder text is being shown on orientation change
        // Guarantees to never show a placeholder if there is an image
        if leftView == nil {
            return super.placeholderRect(forBounds: bounds)
        } else {
            return .null
        }
    }
}

private extension LLChatInputTextField {
    func updatePlaceholderText(with text: String, theme: Theme) {
        self.attributedPlaceholder = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: theme.chatInputPlaceholderTextColor])
    }
    
    func toggleImageMode(imageData: Data?) {
        if let imageData = imageData,
            let image = UIImage(data: imageData) {
            
            let aspectRatio = image.size.width / image.size.height
            let smallWidth = 20 * aspectRatio
           
            // image on left side
            self.leftViewMode = UITextField.ViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: smallWidth, height: 20))
            let image = image.constrained(by: CGSize(width: smallWidth, height: 20))
            imageView.image = image
            self.leftView = imageView
            self.text = nil
            updatePlaceholderText(with: "", theme: theme)
            
        } else {
            self.leftViewMode = UITextField.ViewMode.never
            self.leftView = nil
            updatePlaceholderText(with: placeholderText, theme: theme)
        }
    }
}
