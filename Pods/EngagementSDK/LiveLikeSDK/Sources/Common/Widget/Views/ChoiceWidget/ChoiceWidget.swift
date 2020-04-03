//
//  PredictionWidget.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/15/19.
//

import UIKit

typealias ChoiceWidgetView = WidgetView & ChoiceWidget

enum ChoiceWidgetViewType {
    case text
    case image
}

protocol ChoiceWidget {
    var titleView: WidgetTitleView { get }
    var coreWidgetView: CoreWidgetView { get }
    func playOverlayAnimation(animationFilepath: String)
}
