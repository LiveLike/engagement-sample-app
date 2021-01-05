//
//  AlertWidget.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

enum AlertWidgetViewType {
    case text
    case image
    case both
}

class AlertWidget: ThemeableView {
    let coreWidgetView: CoreWidgetView = {
        let coreWidgetView = CoreWidgetView()
        coreWidgetView.translatesAutoresizingMaskIntoConstraints = false
        return coreWidgetView
    }()

    lazy var titleView: AlertWidgetTitleView = {
        let titleView = AlertWidgetTitleView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        return titleView
    }()

    lazy var contentView: AlertWidgetContentView = {
        let contentView = AlertWidgetContentView(type: type)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    lazy var linkView: AlertWidgetLinkView = {
        let titleView = AlertWidgetLinkView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.clipsToBounds = true
        return titleView
    }()

    var type: AlertWidgetViewType

    init(type: AlertWidgetViewType) {
        self.type = type
        super.init()
        configure()
    }

    private func configure() {
        coreWidgetView.headerView = titleView
        coreWidgetView.contentView = contentView
        coreWidgetView.footerView = linkView

        let bottomConstraint = coreWidgetView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        
        let heightConstraint = coreWidgetView.heightAnchor.constraint(lessThanOrEqualToConstant: 150)
        
        bottomConstraint.priority = .defaultLow
        heightConstraint.priority = .defaultHigh
        
        let contentViewHeightConstraint: NSLayoutConstraint = {
            switch type {
            case .image, .both:
                return contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 90)
            case .text:
                return contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
            }
        }()
        
        addSubview(coreWidgetView)
        NSLayoutConstraint.activate([
            coreWidgetView.topAnchor.constraint(equalTo: self.topAnchor),
            coreWidgetView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            coreWidgetView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bottomConstraint,
            heightConstraint,
            contentViewHeightConstraint
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
}
