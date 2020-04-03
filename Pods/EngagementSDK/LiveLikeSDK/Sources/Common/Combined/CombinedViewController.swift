//
//  CombinedViewController.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-05-14.
//

import UIKit

/**
 Combines the WidgetViewController and ChatViewController to be more conveniently added into your layout.
 */
@objc(LLCombinedViewController)
public class CombinedViewController: UIViewController {
    // MARK: Public properties

    /// A `ContentSession` used by the ChatController to link with the program on the CMS.
    @objc
    public weak var session: ContentSession? {
        didSet {
            widgetController.session = session
            chatController.session = session
        }
    }

    /// The internal WidgetViewController
    @objc
    public let widgetController = WidgetViewController()

    /// The internal ChatViewController
    @objc
    public let chatController = ChatViewController()

    // MARK: Private properties

    private var theme: Theme = .dark

    private lazy var widgetView: PassthroughView = {
        let view = PassthroughView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var chatView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    // MARK: Initializers

    /// :nodoc:
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupContainerViews()
        loadControllers()
    }

    // MARK: View Setup

    private func setupContainerViews() {
        view.addSubview(chatView)
        view.addSubview(widgetView)

        let constraints = [
            chatView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            widgetView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -60.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func loadControllers() {
        widgetController.delegate = self
        chatController.setTheme(theme)
        widgetController.setTheme(theme)
        addChild(viewController: chatController, into: chatView)
        addChild(viewController: widgetController, into: widgetView)
    }

    // MARK: Customization

    /**
     Set the `Theme` for the `ChatViewController`

     - parameter theme: A `Theme` object with values set to suit your product design.

     - note: A theme can be applied at any time and will update the view immediately
     */
    @objc
    public func setTheme(_ theme: Theme) {
        self.theme = theme
        chatController.setTheme(theme)
        widgetController.setTheme(theme)

        log.info("Theme was applied to the CombinedViewController")
    }

    /**
     Pauses the Widgets.
     All future widgets will be discared until resume() is called.
     Any currently displayed widgets will be immediately dismissed.
     */
    public func pauseWidgets() {
        widgetController.pause()
    }

    /**
     Resumes the WidgetViewController.
     All future widgets will be received and rendered normally.
     */
    public func resumeWidgets() {
        widgetController.resume()
    }

    // MARK: Show + Hide

    /**
     Hides the Chat view by animating it off the screen.

     @note The direction of the animation can be changed using `animationDirection`
     */
    @objc
    public func showChat() {
        chatController.show()
    }

    /**
     Shows the Chat view by animating it back onto the screen.
     */
    @objc
    public func hideChat() {
        chatController.hide()
    }
}

extension CombinedViewController: EngagementEventsDelegate {
    func engagementEvent(_ event: EngagementEvent) {
        switch event {
        case .willDismissWidget:
            chatController.messageVC.shrinkGradientOverlay()
        case .didDisplayWidget:
            chatController.messageVC.expandGradientOverlay(height: widgetController.presentedWidget?.viewModelSnapshot.height)
        default:
            break
        }
    }
}
