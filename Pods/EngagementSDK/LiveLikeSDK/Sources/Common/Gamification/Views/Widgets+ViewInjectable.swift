//
//  Widgets+ViewInjectable.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/31/19.
//

import UIKit

protocol ViewInjectable {
    func injectView(_ newView: UIView)
}

extension QuizWidgetViewController: ViewInjectable {
    func injectView(_ newView: UIView) {
        guard let injectableView = quizWidget as? ViewInjectable else {
            assertionFailure("Expected QuizWidgetViewController's view to conform to ViewInjectable.")
            return
        }

        injectableView.injectView(newView)
    }
}

extension PollWidgetViewController: ViewInjectable {
    func injectView(_ newView: UIView) {
        guard let injectableView = widgetView as? ViewInjectable else {
            assertionFailure("Expected PollWidgetViewController's view to conform to ViewInjectable.")
            return
        }

        injectableView.injectView(newView)
    }
}

extension PredictionWidgetViewController: ViewInjectable {
    func injectView(_ newView: UIView) {
        guard let injectableView = predictionWidgetView as? ViewInjectable else {
            assertionFailure("Expected PredictionFollowUpViewController's view to conform to ViewInjectable.")
            return
        }

        injectableView.injectView(newView)
    }
}

extension PredictionFollowUpViewController: ViewInjectable {
    func injectView(_ newView: UIView) {
        guard let injectableView = widgetView as? ViewInjectable else {
            assertionFailure("Expected PredictionFollowUpViewController's view to conform to ViewInjectable.")
            return
        }

        injectableView.injectView(newView)
    }
}

extension VerticalChoiceWidget: ViewInjectable {
    func injectView(_ newView: UIView) {
        addSubview(newView)
        NSLayoutConstraint.activate([
            newView.widthAnchor.constraint(equalToConstant: 100),
            newView.heightAnchor.constraint(equalToConstant: 30),
            newView.topAnchor.constraint(equalTo: coreWidgetView.baseView.bottomAnchor, constant: 8),
            newView.centerXAnchor.constraint(equalTo: coreWidgetView.baseView.centerXAnchor)
        ])
    }
}

extension ImageSliderViewController: ViewInjectable {
    func injectView(_ newView: UIView) {
        view.addSubview(newView)
        NSLayoutConstraint.activate([
            newView.widthAnchor.constraint(equalToConstant: 100),
            newView.heightAnchor.constraint(equalToConstant: 30),
            newView.topAnchor.constraint(equalTo: coreWidgetView.baseView.bottomAnchor, constant: 8),
            newView.centerXAnchor.constraint(equalTo: coreWidgetView.baseView.centerXAnchor)
        ])
    }
}

extension CheerMeterWidgetViewController: ViewInjectable {
    func injectView(_ newView: UIView) {
        view.addSubview(newView)
        NSLayoutConstraint.activate([
            newView.widthAnchor.constraint(equalToConstant: 100),
            newView.heightAnchor.constraint(equalToConstant: 30),
            newView.topAnchor.constraint(equalTo: coreWidgetView.baseView.bottomAnchor),
            newView.centerXAnchor.constraint(equalTo: coreWidgetView.baseView.centerXAnchor)
        ])
    }
}
