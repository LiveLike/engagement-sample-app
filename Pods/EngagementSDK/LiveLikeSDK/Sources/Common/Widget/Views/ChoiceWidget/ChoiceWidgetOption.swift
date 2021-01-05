//
//  ChoiceWidgetOption.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/18/19.
//

import UIKit

typealias ChoiceWidgetOptionButton = UIView & ChoiceWidgetOption

protocol ChoiceWidgetOptionDelegate: AnyObject {
    func wasSelected(_ option: ChoiceWidgetOption)
    func wasDeselected(_ option: ChoiceWidgetOption)
}

protocol ChoiceWidgetOption: AnyObject {
    init(id: String)
    var id: String { get }
    var delegate: ChoiceWidgetOptionDelegate? { get set }
    var borderColor: UIColor { get set }
    func setImage(_ imageURL: URL)
    var text: String? { get set }
    var image: UIImage? { get set }
    func setProgress(_ percent: CGFloat)
    var borderWidth: CGFloat { get set }
    var background: Theme.Background? { get set }
    var descriptionFont: UIFont? { get set }
    var descriptionTextColor: UIColor? { get set }
    var percentageFont: UIFont? { get set }
    var percentageTextColor: UIColor? { get set }
    var barBackground: Theme.Background? { get set }
    var barCornerRadii: Theme.CornerRadii { get set }
    var cornerRadii: Theme.CornerRadii { get set }
    var optionThemeStyle: OptionThemeStyle { get set }
    func applyContainerProperties(_ container: Theme.Container)
}

enum OptionThemeStyle {
    case selected
    case unselected
    case correct
    case incorrect
}
