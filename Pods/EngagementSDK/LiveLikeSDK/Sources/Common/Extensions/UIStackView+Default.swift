//
//  UIStackView+Default.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-31.
//

import UIKit

extension UIStackView {
    static func verticalStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 0
        return stackView
    }
    
    func addBackground(color: UIColor, cornerRadius: CGFloat?) -> UIView {
        let viewTag = 191919
        
        self.viewWithTag(viewTag)?.removeFromSuperview()
        let subview = UIView(frame: bounds)
        subview.backgroundColor = color
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        subview.livelike_cornerRadius = cornerRadius ?? 0.0
        subview.tag = viewTag
        insertSubview(subview, at: 0)
        return subview
    }
    
    func addPadding(viewInsets: UIEdgeInsets) {
        self.isLayoutMarginsRelativeArrangement = true
        self.layoutMargins = viewInsets
    }
}
