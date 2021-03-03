//
//  CustomWidgetTimelineViewController.swift
//  Sample App
//
//  Created by Jelzon Monzon on 3/3/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import EngagementSDK

class CustomWidgetTimelineViewController: WidgetTimelineViewController {

    private var widgetIsInteractableByID: [String: Bool] = [:]

    override func didLoadInitialWidgets(_ widgetModels: [WidgetModel]) -> [WidgetModel] {
        widgetModels.forEach {
            widgetIsInteractableByID[$0.id] = false
        }
        return super.didLoadInitialWidgets(widgetModels)
    }

    override func didLoadMoreWidgets(_ widgetModels: [WidgetModel]) -> [WidgetModel] {
        widgetModels.forEach {
            widgetIsInteractableByID[$0.id] = false
        }
        return super.didLoadMoreWidgets(widgetModels)
    }

    override func didReceiveNewWidget(_ widgetModel: WidgetModel) -> WidgetModel? {
        widgetIsInteractableByID[widgetModel.id] = true
        return super.didReceiveNewWidget(widgetModel)
    }

    override func makeWidget(_ widgetModel: WidgetModel) -> UIViewController? {
        if widgetModel.kind == .socialEmbed {
            return super.makeWidget(widgetModel)
        }

        if widgetIsInteractableByID[widgetModel.id] ?? false {
            return makeInteractableWidget(widgetModel: widgetModel)
        } else {
            return makeResultsWidget(widgetModel: widgetModel)
        }
    }

    func makeInteractableWidget(widgetModel: WidgetModel) -> UIViewController? {
        switch widgetModel {
        case let .poll(model):
            if model.containsImages {
                return CustomImagePollWidgetViewController(model: model)
            }
            return CustomTextPollWidgetViewController(model: model)
        case let .quiz(model):
            if model.containsImages {
                return CustomImageQuizWidgetViewController(model: model)
            }
            return CustomTextQuizWidgetViewController(model: model)
        case let .imageSlider(model):
            return CustomImageSliderViewController(model: model)
        case let .alert(model):
            return CustomAlertWidgetViewController(model: model)
        case let .cheerMeter(model):
            guard model.options.count == 2 else { return nil }
            return CustomCheerMeterWidgetViewController(model: model)
        case let .prediction(model):
            if model.containsImages {
                return CustomImagePredictionWidget(model: model)
            } else {
                return CustomTextPredictionWidgetViewController(model: model)
            }
        case let .predictionFollowUp(model):
            if model.containsImages {
                return CustomImgPredictionFollowUpWidgetVC(model: model)
            } else {
                return CustomTextPredictionFollowUpWidgetViewController(model: model)
            }
        case .socialEmbed:
            return DefaultWidgetFactory.makeWidget(from: widgetModel)
        }
    }

    func makeResultsWidget(widgetModel: WidgetModel) -> UIViewController? {
        switch widgetModel {
        case let .poll(model):
            if model.containsImages {
                return ImagePollWidgetResultsViewController(model: model)
            }
            return TextPollWidgetResultsViewController(model: model)
        case let .quiz(model):
            if model.containsImages {
                return ImageQuizWidgetResultsViewController(model: model)
            }
            return TextQuizWidgetResultsViewController(model: model)
        case let .imageSlider(model):
            return ImageSliderResultsViewController(model: model)
        case let .alert(model):
            let widget = CustomAlertWidgetViewController(model: model)
            widget.timer.isHidden = true
            return widget
        case let .cheerMeter(model):
            guard model.options.count == 2 else { return nil }
            return CheerMeterWidgetResultsViewController(model: model)
        case let .prediction(model):
            if model.containsImages {
                return ImagePredictionWidgetResultsViewController(model: model)
            } else {
                return TextPredictionWidgetResultsViewController(model: model)
            }
        case let .predictionFollowUp(model):
            if model.containsImages {
                return ImagePredictionFollowUpResultsViewController(model: model)
            } else {
                return TextPredictionFollowUpResultsViewController(model: model)
            }
        case .socialEmbed:
            return DefaultWidgetFactory.makeWidget(from: widgetModel)
        }
    }

}
