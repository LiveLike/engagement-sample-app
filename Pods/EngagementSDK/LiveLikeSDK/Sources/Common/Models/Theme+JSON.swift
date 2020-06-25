//
//  Theme+JSON.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/28/20.
//

import Foundation

// MARK: Theme Extensions

extension Theme {
    public static func create(fromJSONObject jsonObject: Any) throws -> Theme {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        let themeResource = try decoder.decode(ThemeResource.self, from: data)
        return Theme()
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
    var header: Component { get }
    var title: Component { get }
    var timer: Component { get }
    var dismiss: Component { get }
    var body: Component { get }
    var footer: Component { get }
}

/// Common picker components between some widgets
private protocol PickerComponentsDecodable: Decodable {
    // Unselected
    var unselectedOption: Component { get }
    var unselectedOptionDescription: Component { get }
    var unselectedOptionImage: Component { get }
    var unselectedOptionPercentage: Component { get }
    var unselectedOptionBar: Component { get }
    
    // Selected
    var selectedOption: Component { get }
    var selectedOptionDescription: Component { get }
    var selectedOptionImage: Component { get }
    var selectedOptionPercentage: Component { get }
    var selectedOptionBar: Component { get }
    
    // Correct
    var correctOption: Component { get }
    var correctOptionDescription: Component { get }
    var correctOptionImage: Component { get }
    var correctOptionPercentage: Component { get }
    var correctOptionBar: Component { get }
    
    // Incorrect
    var incorrectOption: Component { get }
    var incorrectOptionDescription: Component { get }
    var incorrectOptionImage: Component { get }
    var incorrectOptionPercentage: Component { get }
    var incorrectOptionBar: Component { get }
}

private struct LayoutComponents: LayoutComponentsDecodable {
    var header: Component
    var title: Component
    var timer: Component
    var dismiss: Component
    var body: Component
    var footer: Component
}

private struct LayoutAndPickerComponents: LayoutComponentsDecodable, PickerComponentsDecodable {
    
    // MARK: Layout Components
    var header: Component
    var title: Component
    var timer: Component
    var dismiss: Component
    var body: Component
    var footer: Component
    
    // MARK: Picker Components
    
    var unselectedOption: Component
    var unselectedOptionDescription: Component
    var unselectedOptionImage: Component
    var unselectedOptionPercentage: Component
    var unselectedOptionBar: Component
    
    var selectedOption: Component
    var selectedOptionDescription: Component
    var selectedOptionImage: Component
    var selectedOptionPercentage: Component
    var selectedOptionBar: Component
    
    var correctOption: Component
    var correctOptionDescription: Component
    var correctOptionImage: Component
    var correctOptionPercentage: Component
    var correctOptionBar: Component
    
    var incorrectOption: Component
    var incorrectOptionDescription: Component
    var incorrectOptionImage: Component
    var incorrectOptionPercentage: Component
    var incorrectOptionBar: Component
}

private struct Component: Decodable {
    var background: BackgroundProperty
    var borderColor: ColorValue
    var borderRadius: [Number]
    var fontColor: ColorValue
    var fontFamily: [String]
    var fontWeight: FontWeight
    var fontSize: Number
    var margin: [Number]
    var padding: [Number]
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
        case "uniform-gradient":
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
}

private struct Widgets: Decodable {
    var alert: LayoutComponents
    var textPoll: LayoutAndPickerComponents
    var imagePoll: LayoutAndPickerComponents
    var textQuiz: LayoutAndPickerComponents
    var imageQuiz: LayoutAndPickerComponents
    var textPrediction: LayoutAndPickerComponents
    var textPredictionFollowUp: LayoutAndPickerComponents
    var imagePrediction: LayoutAndPickerComponents
    var imagePredictionFollowUp: LayoutAndPickerComponents
    var imageSlider: ImageSlider
    var cheerMeter: CheerMeter
}

private struct ImageSlider: LayoutComponentsDecodable {
    // MARK: Layout Components
    var header: Component
    var title: Component
    var timer: Component
    var dismiss: Component
    var body: Component
    var footer: Component
    
    // MARK: Image Slider Components
    var interactiveTrackLeft: Component
    var interactiveTrackRight: Component
    var resultsTrackLeft: Component
    var resultsTrackRight: Component
    var marker: Component
}

private struct CheerMeter: LayoutComponentsDecodable {
    // MARK: Layout Components
    
    var header: Component
    var title: Component
    var timer: Component
    var dismiss: Component
    var body: Component
    var footer: Component
    
    // MARK: Cheer Meter Components
    
    var sideABar: Component
    var sideAButton: Component
    var sideBBar: Component
    var sideBButton: Component
    var versus: Component
}
