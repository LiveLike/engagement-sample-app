//
//  MMLUseCase2021.swift
//  LiveLikeTestApp
//
//  Created by Mike Moloksher on 1/21/21.
//

import EngagementSDK
import UIKit

class MMLUseCase2021: UIViewController {
    // private var sdk: EngagementSDK!
    // private var session: ContentSession!

    // private let apiOrigin: URL
    private var tabs: UISegmentedControl = {
        let tabs = UISegmentedControl(items: ["Chat", "Widgets"])
        tabs.selectedSegmentIndex = 0
        tabs.translatesAutoresizingMaskIntoConstraints = false
        return tabs
    }()

    private var tabContent: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var chatController: ChatViewController = ChatViewController()
    private var timelineViewController: CustomWidgetTimelineViewController!
    private var liveLikeSDK: LiveLikeSDKBuilder

    init(clientID: String, programID: String) {
        // self.apiOrigin = apiOrigin // TODO: come back
        liveLikeSDK = LiveLikeSDKBuilder(clientID: clientID, programID: programID)
        chatController = liveLikeSDK.getChatViewController()
        timelineViewController = liveLikeSDK.makeTimelineViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tabs.addTarget(self, action: #selector(tabPressed), for: .valueChanged)
        view.addSubview(tabs)
        NSLayoutConstraint.activate([
            tabs.topAnchor.constraint(equalTo: view.topAnchor, constant: 60.0),
            tabs.widthAnchor.constraint(equalTo: view.widthAnchor),
            tabs.heightAnchor.constraint(equalToConstant: 44),
            tabs.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        view.addSubview(tabContent)
        NSLayoutConstraint.activate([
            tabContent.topAnchor.constraint(equalTo: tabs.bottomAnchor),
            tabContent.widthAnchor.constraint(equalTo: view.widthAnchor),
            tabContent.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabContent.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        addChild(viewController: chatController, into: tabContent)
    }

    @objc func tabPressed(sender: UISegmentedControl) {

        tabContent.subviews.forEach { $0.removeFromSuperview() }
        removeAllChildViewControllers()

        if sender.selectedSegmentIndex == 0 {
            addChild(viewController: chatController, into: tabContent)
        } else {
            addChild(viewController: timelineViewController, into: tabContent)
        }
    }
    
    private func addChild(viewController: UIViewController, into view: UIView) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)

        let constraints = [
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    private func removeAllChildViewControllers() {
        self.children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
    }
}
