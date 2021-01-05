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

    private var pendingDispatchWorkItem: DispatchWorkItem?
    private var currentWidget: UIViewController?

    private let widgetBarTimer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

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
        self.view.addSubview(widgetBarTimer)

        let safeArea = self.view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            widgetBarTimer.topAnchor.constraint(equalTo: safeArea.topAnchor),
            widgetBarTimer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetBarTimer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widgetBarTimer.heightAnchor.constraint(equalToConstant: 5),

            widgetView.topAnchor.constraint(equalTo: widgetBarTimer.bottomAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])

    }

    private func setupEngagementSDK() {
        sdk = EngagementSDK.init(config: EngagementSDKConfig(clientID: clientID))
        sdk.delegate = self
        session = sdk.contentSession(config: SessionConfiguration(programID: programID))
        session.delegate = self
    }

    private func displayWidget(_ widget: UIViewController, forTimeInterval timeInterval: TimeInterval) {
        //remove previous widget from display
        dismissCurrentWidget()

        //display widget
        widget.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(widget)
        widget.didMove(toParent: self)
        widgetView.addSubview(widget.view)
        NSLayoutConstraint.activate([
            widget.view.topAnchor.constraint(equalTo: widgetView.topAnchor),
            widget.view.leadingAnchor.constraint(equalTo: widgetView.leadingAnchor),
            widget.view.trailingAnchor.constraint(equalTo: widgetView.trailingAnchor),
            widget.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
        currentWidget = widget

        let dispatchWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.dismissCurrentWidget()
        }

        widgetBarTimer.play(duration: timeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval, execute: dispatchWorkItem)
        self.pendingDispatchWorkItem = dispatchWorkItem
    }

    private func dismissCurrentWidget() {
        currentWidget?.removeFromParent()
        currentWidget?.view.removeFromSuperview()
        pendingDispatchWorkItem?.cancel()
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
extension CustomWidgetsUseCase: ContentSessionDelegate {
    func contentSession(_ session: ContentSession, didReceiveWidget widget: WidgetModel) {
        switch widget {
        case .alert(let model):
            let alertWidget = CustomAlertWidgetViewController(model: model)
            displayWidget(alertWidget, forTimeInterval: model.interactionTimeInterval)
        default:
            print("There is no custom widget for \(widget). Will use default.")
            guard let defaultWidget = DefaultWidgetFactory.makeWidget(from: widget) else { return }
            displayWidget(defaultWidget, forTimeInterval: 30)
        }
    }

    func playheadTimeSource(_ session: ContentSession) -> Date? {
        return nil
    }

    func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {}

    func widget(_ session: ContentSession, didBecomeReady jsonObject: Any) {}

    func widget(_ session: ContentSession, didBecomeReady widget: Widget) {}

    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {
        print("Session status did change \(status)")
    }

    func session(_ session: ContentSession, didReceiveError error: Error) {
        print("Did receive error: \(error.localizedDescription)")
    }

}

// MARK: AccessTokenStorage
extension CustomWidgetsUseCase: AccessTokenStorage {
    func fetchAccessToken() -> String? {
        return Defaults.userAccessToken
    }

    func storeAccessToken(accessToken: String) {
        Defaults.userAccessToken = accessToken
    }
}
