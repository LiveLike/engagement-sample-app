//
//  CustomWidgetsUseCase.swift
//  Sample App
//
//  Copyright © 2021 LiveLike. All rights reserved.
//

import EngagementSDK
import UIKit

class CustomWidgetsUseCase: UIViewController {

    private var sdk: EngagementSDK!
    private var session: ContentSession!

    private let clientID: String
    private let programID: String

    private let widgetViewController = WidgetViewController()

    private let widgetView: UIView = {
        let widgetView = UIView()
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        widgetView.backgroundColor = .lightGray
        return widgetView
    }()

    init(clientID: String, programID: String) {

        self.clientID = clientID
        self.programID = programID

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Widgets"
        setupUI()
        setupEngagementSDK()
    }

    private func setupUI() {
        self.view.addSubview(widgetView)

        let safeArea = self.view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            widgetView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])

        // Add widgetViewController as child view controller
        addChild(widgetViewController)
        widgetView.addSubview(widgetViewController.view)
        widgetViewController.didMove(toParent: self)

        widgetViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widgetViewController.view.bottomAnchor.constraint(equalTo: widgetView.bottomAnchor),
            widgetViewController.view.topAnchor.constraint(equalTo: widgetView.topAnchor),
            widgetViewController.view.trailingAnchor.constraint(equalTo: widgetView.trailingAnchor),
            widgetViewController.view.leadingAnchor.constraint(equalTo: widgetView.leadingAnchor)
        ])

    }

    private func setupEngagementSDK() {
        sdk = EngagementSDK.init(config: EngagementSDKConfig(clientID: clientID))
        sdk.delegate = self
        session = sdk.contentSession(config: SessionConfiguration(programID: programID))

        widgetViewController.delegate = self
        widgetViewController.session = session
    }

    @objc func pauseSession() {
        session?.pause()
    }

    @objc func resumeSession() {
        session?.resume()
    }

}

// MARK: - EngagementSDKDelegate
extension CustomWidgetsUseCase: EngagementSDKDelegate {
    func sdk(_ sdk: EngagementSDK, setupFailedWithError error: Error) {
        let alert = UIAlertController(
            title: "EngagementSDK Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - ContentSessionDelegate
extension CustomWidgetsUseCase: WidgetPopupViewControllerDelegate {
    func widgetViewController(_ widgetViewController: WidgetPopupViewController, willDisplay widget: Widget) { }
    func widgetViewController(_ widgetViewController: WidgetPopupViewController, didDisplay widget: Widget) { }
    func widgetViewController(_ widgetViewController: WidgetPopupViewController, willDismiss widget: Widget) { }
    func widgetViewController(_ widgetViewController: WidgetPopupViewController, didDismiss widget: Widget) { }

    func widgetViewController(
        _ widgetViewController: WidgetPopupViewController,
        willEnqueueWidget widgetModel: WidgetModel
    ) -> Widget? {
        switch widgetModel {
        case .alert(let alertModel):
            return SponsoredAlertWidgetViewController(model: alertModel)
        case .imageSlider(let model):
            return CustomImageSliderViewController(model: model)
        case .quiz(let model):
            if model.containsImages {
                return CustomImageQuizWidgetViewController(model: model)
            }
            return CustomTextQuizWidgetViewController(model: model)
        case .prediction(let model):
            if model.containsImages {
                return CustomImagePredictionWidget(model: model)
            }
            return CustomTextPredictionWidgetViewController(model: model)
        case .predictionFollowUp(let model):
            if model.containsImages {
                return CustomImgPredictionFollowUpWidgetVC(model: model)
            }
            return CustomTextPredictionFollowUpWidgetViewController(model: model)
        case .poll(let model):
            if model.containsImages {
                return CustomImagePollWidgetViewController(model: model)
            } else {
                return CustomTextPollWidgetViewController(model: model)
            }
        case .cheerMeter(let model):
            if model.options.count == 2 {
                return CustomCheerMeterWidgetViewController(model: model)
            }
            return nil
        case .socialEmbed(_):
            return DefaultWidgetFactory.makeWidget(from: widgetModel)
        }
    }
}

// MARK: AccessTokenStorages
extension CustomWidgetsUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
