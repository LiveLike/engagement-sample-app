//
//  SocialEmbedWidgetView.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 2/10/21.
//

import UIKit
import WebKit

class SocialEmbedWidgetView: ThemeableView {
    let coreWidgetView: CoreWidgetView = {
        let coreWidgetView = CoreWidgetView()
        coreWidgetView.translatesAutoresizingMaskIntoConstraints = false
        return coreWidgetView
    }()
    
    private var contentHeightConstraint: NSLayoutConstraint?

    var titleView: WidgetTitleView = {
        let titleView = WidgetTitleView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        return titleView
    }()
    
    var contentView: WKWebView = {
        let webview = WKWebView()
        webview.translatesAutoresizingMaskIntoConstraints = false
        webview.alpha = 0.0
        return webview
    }()

    var contentHeight: CGFloat = 150 {
        didSet {
            contentHeightConstraint?.isActive = false
            contentHeightConstraint?.constant = contentHeight
            contentHeightConstraint?.isActive = true
        }
    }
    
    override init() {
        super.init()
        configure()
    }

    private func configure() {
        coreWidgetView.headerView = titleView
        coreWidgetView.contentView = contentView
                
        addSubview(coreWidgetView)
        NSLayoutConstraint.activate([
            coreWidgetView.topAnchor.constraint(equalTo: self.topAnchor),
            coreWidgetView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            coreWidgetView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            coreWidgetView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        contentHeightConstraint = coreWidgetView.contentView?.heightAnchor.constraint(equalToConstant: contentHeight)
        contentHeightConstraint?.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
}
