//
//  ChatViewController.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-18.
//

import UIKit

public typealias TimestampFormatter = (Date) -> String

/**
 A `ChatViewController` instance represents a view controller that handles chat interaction for the `EngagementSDK`.

 Once an instance of `ChatViewController` has been created, a `ContentSession` object needs to be set to link the `ChatController` with the program/CMS. The 'ContentSession' can be changed at any time.

 The `ChatViewController` can be presented as-is or placed inside a `UIView` as a child UIViewController. See [Apple Documentation](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW1) for more information.

 If the `ChatViewController` is placed inside another view, please take note of the [minimum size restrictions](https://docs.livelike.com/ios/index.html#configure). This restriction can be ignored by setting `ignoreSizeRestrictions`.

 Also, an extension was included for convenience to help add a view controller inside of a specificied view. Please see `UIViewController.addChild(viewController:view:)` for more information
 */

public class ChatViewController: UIViewController {
    // MARK: Properties

    var chatSession: InternalChatSessionProtocol?
    /// The current Chat Session being displayed if any
    public var currentChatSession: ChatSession? {
        return self.chatSession
    }
    
    /// Removes the current chat session if there is one set.
    public func clearChatSession() {
        self.chatSession = nil
        messageViewController.clearChatSession()
        chatInputView.clearChatSession()
    }
    
    /// Sets the chat session to be displayed.
    /// Replaces the current chat session if there is one set.
    public func setChatSession(_ chatSession: ChatSession) {
        self.chatSession = chatSession as? InternalChatSessionProtocol
        messageViewController.setChatSession(chatSession)
        chatInputView.setChatSession(chatSession)

    }

    /// A `ContentSession` used by the ChatController to link with the program on the CMS.
    public weak var session: ContentSession? {
        didSet {
            guard let sessionImpl = session as? InternalContentSession else {
                return
            }

            bindToSessionEvents(session: sessionImpl).catch {
                log.error("Failed to setup chat adapter due to error: \($0)")
            }

            eventRecorder = sessionImpl.eventRecorder
            superPropertyRecorder = sessionImpl.superPropertyRecorder
            peoplePropertyRecorder = sessionImpl.peoplePropertyRecorder

            sessionImpl.getChatSession { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let chatSession):
                    self.setChatSession(chatSession)
                case .failure(let error):
                    log.error(error)
                }
            }

            firstly {
                sessionImpl.whenRewards
            }.then { [weak self] rewards in
                guard let self = self else { return }

                rewards.currentBadgeDidChange.append { [weak self] badge in
                    guard let badge = badge else { return } //ignore nils
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let badgeViewModel = BadgeViewModel(from: badge, rewards: rewards)
                        self?.profileStatusBar.setBadge(badgeViewModel: badgeViewModel)
                    }
                }

                rewards.currentRankDidChange.append { [weak self] rank in
                    // Do not show rank in profile bar unless points > 0
                    guard rewards.currentPoints ?? 0 > 0 else { return }
                    self?.profileStatusBar.setUserRank(userRank: rank)
                }

                rewards.currentPointsDidChange.append { [weak self] points in
                    // If points greater than 0 try updating rank
                    if let rank = rewards.currentRank, points ?? 0 > 0 {
                        self?.profileStatusBar.setUserRank(userRank: rank)
                    }
                    self?.profileStatusBar.setUserRewardPoints(points: points)
                }

            }.catch {
                log.error($0.localizedDescription)
            }
        }
    }

    /// The direction the view should animate in.
    ///
    /// By default the view will animate down in portrait and to the right in landscape.
    /// Setting this value will override the defaults.
    public var animationDirection: Direction = .down {
        didSet {
            resetChatViewPosition()
        }
    }

    /// Use the keyboardDidHideCompletion handler to perform any tasks after the chat keyboard has been hidden
    public var keyboardDidHideCompletion: (() -> Void)?

    /// Use the keyboardDidHideCompletion handler to perform any tasks after the chat keyboard has been shown
    public var keyboardDidShowCompletion: (() -> Void)?

    /// Callback for when the user has sent a chat message.
    public var didSendMessage: (ChatMessage) -> Void = { _ in }

    /// Determines whether the user's profile status bar, above the chat input field, is visible
    public var shouldDisplayProfileStatusBar: Bool = true {
        didSet {
            refreshProfileStatusBarVisibility()
        }
    }

    /// The formatter used print timestamp labels on the chat message.
    /// Set to nil to hide the timestamp labels.
    public var messageTimestampFormatter: TimestampFormatter? {
        get {
            messageViewController.messageTimestampFormatter
        }
        set {
            messageViewController.messageTimestampFormatter = newValue
        }
    }

    /// Determines whether the user is able to post images into chat
    public var shouldSupportChatImagePosting: Bool {
        get {
            return chatInputView.supportExternalImages
        }
        set {
            chatInputView.supportExternalImages = newValue
        }
    }

    /// Show or hide the input field for chat
    public var isChatInputVisible: Bool = true {
        didSet {
            self.inputViewHeightConstraint.constant = isChatInputVisible ? 52 : 0
            self.chatInputView.reset()
        }
    }
    
    /// Toggles whether new message will be displayed. Messages received while `false` will catch up when set to `true`
    public var shouldShowIncomingMessages: Bool = true {
        didSet {
            self.messageViewController.shouldShowIncomingMessages = shouldShowIncomingMessages
        }
    }

    /// Determines whether the user is able to post images into chat
    public var shouldDisplayDebugVideoTime: Bool {
        get {
            messageViewController.shouldDisplayDebugVideoTime
        }
        set {
            messageViewController.shouldDisplayDebugVideoTime = newValue
        }
    }

    // MARK: Internal Properties

    public var messageViewController: MessageViewController = {
        let messagesVC = MessageViewController()
        return messagesVC
    }()
    
    public var chatInputView: ChatInputView = {
        ChatInputView.instanceFromNib()
    }()

    public var ignoreSizeRestrictions = false
    
    lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.frame = self.messageContainerView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0.0, 0.0, 0.1, 0.95, 1.0]
        self.messageContainerView.layer.mask = gradient
        return gradient
    }()

    lazy var inputContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    lazy var messageContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    let profileStatusBar: UserProfileStatusBar = {
        let profileStatusBar = UserProfileStatusBar()
        profileStatusBar.translatesAutoresizingMaskIntoConstraints = false
        return profileStatusBar
    }()

    var inputContainerBottomConstraint: NSLayoutConstraint!
    var profileStatusBarHeightConstraint: NSLayoutConstraint?
    var isOnScreen = true
    var pauseTimer: Timer?
    var keyboardNotificationTokens = [NSObjectProtocol]()
    var recentlyUsedStickers = LimitedArray<Sticker>(maxSize: 30)
    var isRotating = false
    var keyboardType: KeyboardType = .standard
    
    // Analytic Properties
    var eventRecorder: EventRecorder?
    var superPropertyRecorder: SuperPropertyRecorder?
    var peoplePropertyRecorder: PeoplePropertyRecorder?
    var chatVisibilityStatus: VisibilityStatus = .shown
    var timeVisibilityChanged: Date = Date()
    var timeChatPauseStatusChanged: Date = Date()
    lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didRecognizeTapGesture))
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    // MARK: Private Properties

    private let minimumContainerWidth: CGFloat = 292
    private var currentContainerWidth: CGFloat = 0 {
        didSet {
            validateContainerWidth()
        }
    }
    private lazy var inputViewHeightConstraint: NSLayoutConstraint = inputContainerView.heightAnchor.constraint(equalToConstant: 52.0)
    private var theme: Theme = .dark
    private var displayNameVendor: UserNicknameVendor?

    // MARK: Initializers

    /// :nodoc:
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: Lifecycle

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.isHidden = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupContainerViews()
            self.setupInputViews()
            self.setupMessageView()
            self.addKeyboardNotifications()
            self.setTheme(self.theme)
        }
    }

    /// :nodoc:
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardDismissGesture()
        UIAccessibility.post(notification: .layoutChanged, argument: self.chatInputView.textField)
    }

    /// :nodoc:
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardDismissGesture()
        resignFirstResponder()
    }

    /// :nodoc:
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currentContainerWidth = view.frame.width

        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        gradientLayer.frame = self.messageContainerView.bounds
        CATransaction.commit()
    }

    /// :nodoc:
    public override func willTransition(to newCollection: UITraitCollection,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // Save the visible row position
            self?.isRotating = true
            self?.messageViewController.orientationWillChange()
        }, completion: { [weak self] _ in
            // Scroll to the saved position prior to screen rotate
            self?.messageViewController.orientationDidChange()
            self?.isRotating = false
        })
        super.willTransition(to: newCollection, with: coordinator)
    }

    // MARK: View setup

    private func setupContainerViews() {
        view.addSubview(messageContainerView)
        view.addSubview(inputContainerView)
        view.addSubview(profileStatusBar)

        inputContainerBottomConstraint = view.safeBottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor)
        profileStatusBarHeightConstraint = profileStatusBar.heightAnchor.constraint(equalToConstant: 0)
        
        let constraints = [
            inputContainerBottomConstraint!,
            inputContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            inputContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            inputViewHeightConstraint,
            messageContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            messageContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            messageContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            messageContainerView.bottomAnchor.constraint(equalTo: profileStatusBar.topAnchor),

            profileStatusBar.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            profileStatusBar.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            profileStatusBar.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -8)
        ]

        NSLayoutConstraint.activate(constraints)
        profileStatusBarHeightConstraint?.isActive = true
    }

    private func setupMessageView() {
        addChild(viewController: messageViewController, into: messageContainerView)
    }

    private func setupInputViews() {
        chatInputView.setTheme(theme)
        chatInputView.delegate = self

        inputContainerView.addSubview(chatInputView)
        chatInputView.constraintsFill(to: inputContainerView)

        refreshProfileStatusBarVisibility()
        profileStatusBar.isHidden = true
    }

    // MARK: Customization

    /**
     Set the `Theme` for the `ChatViewController`

     - parameter theme: A `Theme` object with values set to suit your product design.

     - note: A theme can be applied at any time and will update the view immediately
     */
    public func setTheme(_ theme: Theme) {
        self.theme = theme
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.messageViewController.setTheme(theme)
            self.chatInputView.setTheme(theme)
            self.profileStatusBar.setTheme(theme)

            self.view.backgroundColor = theme.chatBodyColor

            log.info("Theme was applied to the ChatViewController")
        }
    }
}

private extension ChatViewController {
    func validateContainerWidth() {
        let isValid = ignoreSizeRestrictions || currentContainerWidth >= minimumContainerWidth
        view.isHidden = !isValid
        if !isValid {
            let message =
                """
                \(String(describing: type(of: self))) could not be displayed.
                \(String(describing: type(of: self))) has a view width of \(currentContainerWidth).
                However it requires a width of \(minimumContainerWidth)
                """
            log.severe(message)
        }
    }

    private func bindToSessionEvents(session: InternalContentSession) -> Promise<Void> {
        session.nicknameVendor.nicknameDidChange.append { [weak self] nickname in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard self.isViewLoaded else { return }
                self.profileStatusBar.displayName = nickname
                self.refreshProfileStatusBarVisibility()
            }
        }

        return Promise(value: ())
    }
}
