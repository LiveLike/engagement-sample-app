//
//  PredictionWidget.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/15/19.
//

import UIKit

protocol ChoiceWidgetDelegate: AnyObject {
    func choiceWidget(_ choiceWidget: ChoiceWidget, optionSelected: ChoiceWidgetOption)
}

protocol ChoiceWidget: ThemeableView {
    var titleView: WidgetTitleView { get }
    var coreWidgetView: CoreWidgetView { get }
    func playOverlayAnimation(animationFilepath: String, completion: (() -> Void)?)
    func stopOverlayAnimation()
    func addOption(withID id: String, prepare option: (ChoiceWidgetOption) -> Void)
    
    var headerBodySpacing: CGFloat { get set }
    var optionSpacing: CGFloat { get set }
    var bodyBackground: Theme.Background? { get set }
    var options: [ChoiceWidgetOptionButton] { get }

}
