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

class AlertWidget: WidgetView {
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
        super.init(frame: .zero)
        configure()
    }

    private func configure() {
        coreWidgetView.headerView = nil
        coreWidgetView.contentView = contentView
        coreWidgetView.footerView = linkView

        addSubview(coreWidgetView)
        addSubview(titleView)

        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: coreWidgetView.leadingAnchor, constant: -6),
            titleView.topAnchor.constraint(equalTo: coreWidgetView.topAnchor, constant: -12),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 90)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
}
