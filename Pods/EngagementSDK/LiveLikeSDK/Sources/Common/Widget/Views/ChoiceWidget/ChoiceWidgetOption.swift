//
//  ChoiceWidgetOption.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/18/19.
//

import UIKit

typealias ChoiceWidgetOptionButton = UIButton & ChoiceWidgetOption

protocol ChoiceWidgetOption: AnyObject {
    var id: String { get }
    func setText(_ text: String, theme: Theme)
    func setBorderColor(_ color: UIColor)
    func setColors(_ colors: ChoiceWidgetOptionColors)
    func customize(_ theme: Theme)
    var onButtonPressed: ((ChoiceWidgetOptionButton) -> Void)? { get set }
    func setImage(_ imageURL: URL)
    func setProgress(_ percent: CGFloat)
    var isSelected: Bool { get set }
}

struct ChoiceWidgetOptionFactory {
    enum Style {
        case wideText
        case wideTextImage
    }

    func create(style: Style, id: String) -> ChoiceWidgetOptionButton {
        switch style {
        case .wideText: return TextChoiceWidgetOptionButton(id: id)
        case .wideTextImage: return WideTextImageChoice(id: id)
        }
    }
}
