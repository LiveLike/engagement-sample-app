//
//  Theme+JSON.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/28/20.
//

import Foundation
import UIKit

// MARK: Theme Extensions

extension Theme {
    
    /// Creates a `Theme` from a theme json
    /// - Parameter jsonObject: A theme json object compatable with `JSONSerialization.data(withJSONObject:options:)`
    public static func create(fromJSONObject jsonObject: Any) throws -> Theme {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        let resource = try decoder.decode(ThemeResource.self, from: data)
    
        let theme = Theme()

        if let quiz = resource.widgets.quiz {
            try theme.widgets.quiz.apply(quiz)
        }

        if let poll = resource.widgets.poll {
            try theme.widgets.poll.apply(poll)
        }

        if let prediction = resource.widgets.prediction {
            try theme.widgets.prediction.apply(prediction)
        }

        if let alert = resource.widgets.alert {
            try theme.widgets.alert.apply(alert)
        }
        
        return theme
    }
    
    private static func background(from backgroundProperty: BackgroundProperty) throws -> Background {
        switch backgroundProperty {
        case .fill(let fill):
            return .fill(color: try Theme.uiColor(from: fill.color))
        case .uniformGradient(let gradient):
            return .gradient(
                gradient: Background.Gradient(
                    colors: try gradient.colors.map { try Theme.uiColor(from: $0) },
                    start: CGPoint(x: 0, y: 0.5),
                    end: CGPoint(x: 1, y: 0.5)
                )
            )
        case .unsupported:
            throw ThemeErrors.unsupportedBackgroundProperty
        }
    }
    
    private static func uiColor(from colorValue: ColorValue) throws -> UIColor {
        guard let color = UIColor(hexaRGBA: colorValue) else {
            throw ThemeErrors.invalidColorValue
        }
        return color
    }

    private static func uiFont(
        fontNames: [String],
        fontWeight: FontWeight,
        fontSize: Number
    ) -> UIFont? {
        var fontNamesSet: Set<String> = Set()
        UIFont.familyNames.forEach { fontFamily in
            let fontNames = UIFont.fontNames(forFamilyName: fontFamily)
            fontNames.forEach { fontName in
                fontNamesSet.insert(fontName)
            }
        }

        for fontName in fontNames {
            if fontNamesSet.contains(fontName) {
                return Theme.uiFont(
                    fontName: fontName,
                    size: CGFloat(fontSize),
                    weight: fontWeight.uiFontWeight
                )
            }
        }
        return nil
    }

    private static func uiFont(fontName: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let fontDescriptor = UIFontDescriptor(name: fontName, size: size)
            .withWeight(weight)
        return UIFont(descriptor: fontDescriptor, size: CGFloat(size))
    }

    private static func cornerRadii(borderRadius: [Number]) throws -> CornerRadii {
        guard
            let topLeft = borderRadius[safe: 0],
            let topRight = borderRadius[safe: 1],
            let bottomLeft = borderRadius[safe: 2],
            let bottomRight = borderRadius[safe: 3]
        else {
            throw NilError()
        }

        return CornerRadii(
            topLeft: CGFloat(topLeft),
            topRight: CGFloat(topRight),
            bottomLeft: CGFloat(bottomLeft),
            bottomRight: CGFloat(bottomRight)
        )
    }
}

private extension UIFontDescriptor {
    func withWeight(_ weight: UIFont.Weight) -> UIFontDescriptor {
        var attributes = fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        traits[.weight] = weight
        attributes[.traits] = traits
        return UIFontDescriptor(fontAttributes: attributes)
    }
}

private enum PickerComponentState {
    case unselected
    case selected
    case correct
    case incorrect
}

private struct PickerComponentGroup {
    var option: Component?
    var description: Component?
    var image: Component?
    var percentage: Component?
    var bar: Component?

    init(
        pickerComponents: PickerComponentsDecodable,
        state: PickerComponentState
    ) {
        switch state {
        case .correct:
            option = pickerComponents.correctOption
            description = pickerComponents.correctOptionDescription
            image = pickerComponents.correctOptionImage
            percentage = pickerComponents.correctOptionPercentage
            bar = pickerComponents.correctOptionBar
        case .incorrect:
            option = pickerComponents.incorrectOption
            description = pickerComponents.incorrectOptionDescription
            image = pickerComponents.incorrectOptionImage
            percentage = pickerComponents.incorrectOptionPercentage
            bar = pickerComponents.incorrectOptionBar
        case .selected:
            option = pickerComponents.selectedOption
            description = pickerComponents.selectedOptionDescription
            image = pickerComponents.selectedOptionImage
            percentage = pickerComponents.selectedOptionPercentage
            bar = pickerComponents.selectedOptionBar
        case .unselected:
            option = pickerComponents.unselectedOption
            description = pickerComponents.unselectedOptionDescription
            image = pickerComponents.unselectedOptionImage
            percentage = pickerComponents.unselectedOptionPercentage
            bar = pickerComponents.unselectedOptionBar
        }
    }
}

private extension Theme.Container {
    mutating func apply(_ component: Component) throws {
        if let background = component.background {
            self.background = try Theme.background(from: background)
        }

        if let borderColor = component.borderColor {
            self.borderColor = try Theme.uiColor(from: borderColor)
        }

        if let borderWidth = component.borderWidth {
            self.borderWidth = CGFloat(borderWidth)
        }

        if let cornerRadii = component.borderRadius {
            self.cornerRadii = try Theme.cornerRadii(borderRadius: cornerRadii)
        }
    }
}

private extension Theme.ChoiceWidget {
    mutating func apply(_ widgetComponents: LayoutAndPickerComponents) throws {
        if let main = widgetComponents.root {
            try self.main.apply(main)
        }

        if let header = widgetComponents.header {
            try self.header.apply(header)
        }

        if let body = widgetComponents.body {
            try self.body.apply(body)
        }

        if let title = widgetComponents.title {
            try self.title.apply(title)
        }

        try self.selectedOption.apply(PickerComponentGroup(
            pickerComponents: widgetComponents,
            state: .selected)
        )

        try self.unselectedOption.apply(PickerComponentGroup(
            pickerComponents: widgetComponents,
            state: .unselected)
        )

        try self.correctOption?.apply(PickerComponentGroup(
            pickerComponents: widgetComponents,
            state: .correct)
        )

        try self.incorrectOption?.apply(PickerComponentGroup(
            pickerComponents: widgetComponents,
            state: .incorrect)
        )
    }
}

private extension Theme.AlertWidget {
    mutating func apply(_ alertWidget: LayoutComponents) throws {
        if let main = alertWidget.root {
            try self.main.apply(main)
        }

        if let header = alertWidget.header {
            try self.header.apply(header)
        }

        if let title = alertWidget.title {
            try self.title.apply(title)
        }

        if let body = alertWidget.body {
            try self.body.apply(body)
            try self.description.apply(body)
        }

        if let footer = alertWidget.footer {
            try self.footer.apply(footer)
            try self.link.apply(footer)
        }
    }
}

private extension Theme.ChoiceWidget.Option {
    mutating func apply(_ option: PickerComponentGroup) throws {
        if let container = option.option {
            try self.container.apply(container)
        }

        if let description = option.description {
            try self.description.apply(description)
        }

        if let percentage = option.percentage {
            try self.percentage.apply(percentage)
        }

        if let progressBar = option.bar {
            try self.progressBar.apply(progressBar)
        }
    }
}

private extension Theme.ProgressBar {
    mutating func apply(_ component: Component) throws {
        if let background = component.background {
            self.background = try Theme.background(from: background)
        }

        if let borderColor = component.borderColor {
            self.borderColor = try Theme.uiColor(from: borderColor)
        }

        if let borderWidth = component.borderWidth {
            self.borderWidth = CGFloat(borderWidth)
        }

        if let cornerRadii = component.borderRadius {
            self.cornerRadii = try Theme.cornerRadii(borderRadius: cornerRadii)
        }
    }
}

private extension Theme.Text {
    mutating func apply(_ component: Component) throws {
        if let textColor = component.fontColor {
            self.color = try Theme.uiColor(from: textColor)
        }

        let fontSize = component.fontSize ?? Number(self.font.pointSize)
        let fontFamilies = component.fontFamily ?? [self.font.fontName]

        if let font = Theme.uiFont(
            fontNames: fontFamilies,
            fontWeight: component.fontWeight ?? .normal,
            fontSize: fontSize
        ) {
            self.font = font
        }
    }
}

private extension UIColor {
    convenience init?(hexaRGBA: String) {
        var chars = Array(hexaRGBA.hasPrefix("#") ? hexaRGBA.dropFirst() : hexaRGBA[...])
        switch chars.count {
        case 3: chars = chars.flatMap { [$0, $0] }; fallthrough
        case 6: chars.append(contentsOf: ["F", "F"])
        case 8: break
        default: return nil
        }
        self.init(red: .init(strtoul(String(chars[0...1]), nil, 16)) / 255,
                green: .init(strtoul(String(chars[2...3]), nil, 16)) / 255,
                 blue: .init(strtoul(String(chars[4...5]), nil, 16)) / 255,
                alpha: .init(strtoul(String(chars[6...7]), nil, 16)) / 255)
    }
}

// MARK: Type Definitions

private typealias Number = Double
private typealias ColorValue = String

private struct ThemeResource: Decodable {
    var version: Number
    var widgets: Widgets
}

/// Common layout components between most widgets
private protocol LayoutComponentsDecodable: Decodable {
    var root: Component? { get }
    var header: Component? { get }
    var title: Component? { get }
    var timer: Component? { get }
    var dismiss: Component? { get }
    var body: Component? { get }
    var footer: Component? { get }
}

/// Common picker components between some widgets
private protocol PickerComponentsDecodable: Decodable {
    // Unselected
    var unselectedOption: Component? { get }
    var unselectedOptionDescription: Component? { get }
    var unselectedOptionImage: Component? { get }
    var unselectedOptionPercentage: Component? { get }
    var unselectedOptionBar: Component? { get }
    
    // Selected
    var selectedOption: Component? { get }
    var selectedOptionDescription: Component? { get }
    var selectedOptionImage: Component? { get }
    var selectedOptionPercentage: Component? { get }
    var selectedOptionBar: Component? { get }
    
    // Correct
    var correctOption: Component? { get }
    var correctOptionDescription: Component? { get }
    var correctOptionImage: Component? { get }
    var correctOptionPercentage: Component? { get }
    var correctOptionBar: Component? { get }
    
    // Incorrect
    var incorrectOption: Component? { get }
    var incorrectOptionDescription: Component? { get }
    var incorrectOptionImage: Component? { get }
    var incorrectOptionPercentage: Component? { get }
    var incorrectOptionBar: Component? { get }
}

private struct LayoutComponents: LayoutComponentsDecodable {
    var root: Component?
    var header: Component?
    var title: Component?
    var timer: Component?
    var dismiss: Component?
    var body: Component?
    var footer: Component?
}

private struct LayoutAndPickerComponents: LayoutComponentsDecodable, PickerComponentsDecodable {

    // MARK: Layout Components
    var root: Component?
    var header: Component?
    var title: Component?
    var timer: Component?
    var dismiss: Component?
    var body: Component?
    var footer: Component?
    
    // MARK: Picker Components
    
    var unselectedOption: Component?
    var unselectedOptionDescription: Component?
    var unselectedOptionImage: Component?
    var unselectedOptionPercentage: Component?
    var unselectedOptionBar: Component?
    
    var selectedOption: Component?
    var selectedOptionDescription: Component?
    var selectedOptionImage: Component?
    var selectedOptionPercentage: Component?
    var selectedOptionBar: Component?
    
    var correctOption: Component?
    var correctOptionDescription: Component?
    var correctOptionImage: Component?
    var correctOptionPercentage: Component?
    var correctOptionBar: Component?
    
    var incorrectOption: Component?
    var incorrectOptionDescription: Component?
    var incorrectOptionImage: Component?
    var incorrectOptionPercentage: Component?
    var incorrectOptionBar: Component?
}

private struct Component: Decodable {
    var background: BackgroundProperty?
    var borderColor: ColorValue?
    var borderRadius: [Number]?
    var borderWidth: Number?
    var fontColor: ColorValue?
    var fontFamily: [String]?
    var fontWeight: FontWeight?
    var fontSize: Number?
}

private enum BackgroundProperty: Decodable {
    case fill(FillBackground)
    case uniformGradient(UniformGradientBackground)
    case unsupported
    
    private enum CodingKeys: String, CodingKey {
        case format
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let format = try container.decode(String.self, forKey: .format)
        
        switch format {
        case "fill":
            self = try .fill(FillBackground(from: decoder))
        case "uniformGradient":
            self = try .uniformGradient(UniformGradientBackground(from: decoder))
        default:
            self = .unsupported
        }
    }
    
    struct FillBackground: Decodable {
        var color: ColorValue
    }
    
    struct UniformGradientBackground: Decodable {
        var colors: [ColorValue]
        var direction: Number
    }
}

private enum FontWeight: String, Decodable {
    case light
    case normal
    case bold

    var uiFontWeight: UIFont.Weight {
        switch self {
        case .light:
            return .light
        case .normal:
            return .regular
        case .bold:
            return .bold
        }
    }
}

private struct Widgets: Decodable {
    var alert: LayoutComponents?
    var poll: LayoutAndPickerComponents?
    var quiz: LayoutAndPickerComponents?
    var prediction: LayoutAndPickerComponents?
    var imageSlider: ImageSlider?
    var cheerMeter: CheerMeterComponents?
}

private struct ImageSlider: LayoutComponentsDecodable {
    // MARK: Layout Components
    var root: Component?
    var header: Component?
    var title: Component?
    var timer: Component?
    var dismiss: Component?
    var body: Component?
    var footer: Component?
    
    // MARK: Image Slider Components
    var interactiveTrackLeft: Component?
    var interactiveTrackRight: Component?
    var resultsTrackLeft: Component?
    var resultsTrackRight: Component?
    var marker: Component?
}

private struct CheerMeterComponents: LayoutComponentsDecodable {

    // MARK: Layout Components
    var root: Component?
    var header: Component?
    var title: Component?
    var timer: Component?
    var dismiss: Component?
    var body: Component?
    var footer: Component?
    
    // MARK: Cheer Meter Components
    
    var sideABar: Component?
    var sideAButton: Component?
    var sideBBar: Component?
    var sideBButton: Component?
    var versus: Component?
}
