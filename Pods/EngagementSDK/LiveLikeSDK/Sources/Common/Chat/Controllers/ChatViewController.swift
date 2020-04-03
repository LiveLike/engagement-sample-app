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

@objc(LLChatViewController)
public class ChatViewController: UIViewController {
    // MARK: Properties

    var chatAdapter: ChatAdapter? {
        didSet {
            messageVC.chatAdapter = chatAdapter
            chatAdapter?.hideSnapToLive = { [weak self] hide in
                self?.snapToLiveIsHidden(hide)
            }
            chatAdapter?.didScrollToTop = { [weak self] in
                self?.loadMoreHistory()
            }
            chatAdapter?.timestampFormatter = self.messageTimestampFormatter
            chatAdapter?.shouldDisplayDebugVideoTime = self.shouldDisplayDebugVideoTime
            chatInputViewAccessory.supportExternalImages = self.shouldSupportChatImagePosting
            
            chatAdapter?.setTheme(theme)
        }
    }

    /// A `ContentSession` used by the ChatController to link with the program on the CMS.
    @objc
    public weak var session: ContentSession? {
        didSet {
            guard let sessionImpl = session as? InternalContentSession else {
                return
            }

            bindToSessionEvents(session: sessionImpl).catch {
                log.error("Failed to setup chat adapter due to error: \($0)")
            }

            sessionImpl.chatDelegate = self

            stickerRepo = sessionImpl.stickerRepository
            eventRecorder = sessionImpl.eventRecorder
            superPropertyRecorder = sessionImpl.superPropertyRecorder
            peoplePropertyRecorder = sessionImpl.peoplePropertyRecorder
            messageVC.session = sessionImpl

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
    @objc
    public var animationDirection: Direction = .down {
        didSet {
            resetChatViewPosition()
        }
    }

    /// Use the keyboardDidHideCompletion handler to perform any tasks after the chat keyboard has been hidden
    @objc
    public var keyboardDidHideCompletion: (() -> Void)?

    /// Use the keyboardDidHideCompletion handler to perform any tasks after the chat keyboard has been shown
    @objc
    public var keyboardDidShowCompletion: (() -> Void)?

    /// Callback for when the user has sent a chat message.
    @objc public var didSendMessage: (ChatMessage) -> Void = { _ in }

    /// Determines whether the user's profile status bar, above the chat input field, is visible
    @objc
    public var shouldDisplayProfileStatusBar: Bool = true {
        didSet {
            refreshProfileStatusBarVisibility()
        }
    }

    /// The formatter used print timestamp labels on the chat message.
    /// Set to nil to hide the timestamp labels.
    @objc public var messageTimestampFormatter: TimestampFormatter? = { date in
        let dateFormatter = DateFormatter()
        dateFormatter.amSymbol = "am"
        dateFormatter.pmSymbol = "pm"
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d hh:mm")
        return dateFormatter.string(from: date)
    }

    /// Determines whether the user is able to post images into chat
    @objc public var shouldSupportChatImagePosting: Bool = true {
        didSet {
            self.chatInputViewAccessory.supportExternalImages = shouldSupportChatImagePosting
        }
    }
    
    /// Determines whether the user is able to post images into chat
    @objc public var shouldDisplayDebugVideoTime: Bool = false
    
    var stickerRepo: StickerRepository? {
        didSet {
            refreshStickers()
        }
    }

    // MARK: Internal Properties

    lazy var messageVC: MessageViewController = {
        let messagesVC = MessageViewController()
        messagesVC.setTheme(theme)
        messagesVC.chatAdapter = chatAdapter
        messagesVC.session = self.session as? InternalContentSession
        return messagesVC
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

    var ignoreSizeRestrictions = false
    var isOnScreen = true
    var pauseTimer: Timer?

    var keyboardNotificationTokens = [NSObjectProtocol]()

    // MARK: Private Properties

    private var snapToLiveButton = SnapToLiveButton()
    private var snapToLiveBottomConstraint: NSLayoutConstraint?

    private let minimumContainerWidth: CGFloat = 292
    private var currentContainerWidth: CGFloat = 0 {
        didSet {
            validateContainerWidth()
        }
    }

    lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didRecognizeTapGesture))
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    lazy var chatInputViewAccessory: ChatInputView = {
        ChatInputView.instanceFromNib()
    }()

    lazy var stickerInputView: StickerInputView = {
        let stickerInputView = StickerInputView.instanceFromNib()
        stickerInputView.delegate = self
        return stickerInputView
    }()

    private var theme: Theme = .dark
    private var displayNameVendor: UserNicknameVendor?
    var isRotating = false

    var keyboardIsVisible = false
    var keyboardType: KeyboardType = .standard

    // Analytic Properties
    var eventRecorder: EventRecorder?
    var superPropertyRecorder: SuperPropertyRecorder?
    var peoplePropertyRecorder: PeoplePropertyRecorder?
    var chatVisibilityStatus: VisibilityStatus = .shown
    var timeVisibilityChanged: Date = Date()

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
            self.setTheme(self.theme)
            self.setupContainerViews()
            self.setupInputViews()
            self.setupMessageView()
            self.setupSnapToLiveButton()
            self.addKeyboardNotifications()
        }
    }

    /// :nodoc:
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardDismissGesture()
        UIAccessibility.post(notification: .layoutChanged, argument: self.chatInputViewAccessory.textField)
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
    }

    /// :nodoc:
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        chatAdapter?.orientationWillChange()
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.chatAdapter?.orientationDidChange()
            self?.isRotating = false
        }

        isRotating = true
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
            inputContainerView.heightAnchor.constraint(equalToConstant: 52.0),
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
        addChild(viewController: messageVC, into: messageContainerView)
    }

    private func setupInputViews() {
        chatInputViewAccessory.setTheme(theme)
        chatInputViewAccessory.delegate = self

        inputContainerView.addSubview(chatInputViewAccessory)
        chatInputViewAccessory.constraintsFill(to: inputContainerView)

        refreshProfileStatusBarVisibility()
        profileStatusBar.isHidden = true
    }

    // MARK: Snap to live

    private func setupSnapToLiveButton() {
        snapToLiveButton.translatesAutoresizingMaskIntoConstraints = false
        snapToLiveButton.alpha = 0.0
        view.addSubview(snapToLiveButton)
        snapToLiveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        snapToLiveBottomConstraint = snapToLiveButton.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        snapToLiveBottomConstraint?.isActive = true
        snapToLiveButton.addGestureRecognizer({
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(snapToLive))
            tapGestureRecognizer.numberOfTapsRequired = 1
            return tapGestureRecognizer
        }())
        snapToLiveIsHidden(true)
    }

    @objc func snapToLive() {
        chatAdapter?.shouldScrollToNewestMessageOnArrival = true
        chatAdapter?.scrollToMostRecent(force: true, returnMethod: .snapToLive)
    }

    private func snapToLiveIsHidden(_ isHidden: Bool) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.snapToLiveBottomConstraint?.constant = isHidden ? self.snapToLiveButton.bounds.height : -16
            self.view.layoutIfNeeded()
            self.snapToLiveButton.alpha = isHidden ? 0 : 1
        }, completion: nil)
    }

    func sendMessage(_ message: ChatInputMessage) {
        guard let sessionImpl = session as? InternalContentSession else {
            return
        }
        guard let nickname = sessionImpl.nicknameVendor.currentNickname else {
            assertionFailure("Tried to send message before nickname is available.")
            return
        }

        sessionImpl.sendChatMessage(message)?.then { [weak self] chatMessageID in
            guard let self = self else { return }

            self.didSendMessage(
                ChatMessage(
                    senderUsername: nickname,
                    message: message.message,
                    timestamp: Date()
                )
            )
            
            guard let messageText = message.message else { return }
            
            let stickerIDs = messageText.stickerIDs
            if let stickers = self.stickerRepo?.getStickerPacks() {
                let indices = ChatSentMessageProperties.calculateStickerIndices(stickerIDs: stickerIDs, stickers: stickers)
                let sentProperties = ChatSentMessageProperties(
                    characterCount: messageText.count,
                    messageId: chatMessageID.asString,
                    stickerIDs: stickerIDs,
                    stickerCount: stickerIDs.count,
                    stickerIndices: indices,
                    hasExternalImage: message.imageURL != nil
                )
                self.eventRecorder?.record(.chatMessageSent(properties: sentProperties))
            }

            var superProps = [SuperProperty]()
            let now = Date()
            superProps.append(.timeOfLastChatMessage(time: now))
            if messageText.containsEmoji {
                superProps.append(.timeOfLastEmoji(time: now))
            }
            self.superPropertyRecorder?.register(superProps)

            self.peoplePropertyRecorder?.record([.timeOfLastChatMessage(time: now)])

            let keyboardProperties = KeyboardHiddenProperties(keyboardType: self.keyboardType, keyboardHideMethod: .messageSent, messageID: chatMessageID.asString)
            self.eventRecorder?.record(.keyboardHidden(properties: keyboardProperties))
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    // MARK: Chat history

    func loadNewestMessages() {
        guard let session = session as? InternalContentSession else { return }
        guard let chatRoom = session.currentChatRoom else { return }
        let limit = session.config.chatHistoryLimit

        messageVC.isLoading(true)

        firstly {
            bindToSessionEvents(session: session)
        }.then { _ in
            chatRoom.loadNewestMessagesFromHistory(limit: limit)
        }.always {
            self.messageVC.isLoading(false)
        }.catch { error in
            log.error("Failed to load history: \(error.localizedDescription)")
        }
    }
    
    func loadMoreHistory(){
        guard let session = session as? InternalContentSession else { return }
        guard let chatRoom = session.currentChatRoom else { return }
        let limit = session.config.chatHistoryLimit
        
        messageVC.isLoading(true)
        
        firstly {
            bindToSessionEvents(session: session)
        }.then {
            chatRoom.loadPreviousMessagesFromHistory(limit: limit)
        }.always {
            self.messageVC.isLoading(false)
        }.catch { error in
            log.error("Failed to load history: \(error.localizedDescription)")
        }
    }

    func loadInitialHistory(){
        guard let session = session as? InternalContentSession else { return }
        guard let chatRoom = session.currentChatRoom else { return }
        let limit = session.config.chatHistoryLimit

        messageVC.isLoading(true)

        firstly {
            bindToSessionEvents(session: session)
        }.then {
            chatRoom.loadInitialHistory(limit: limit)
        }.always {
            self.messageVC.isLoading(false)
        }.catch { error in
            log.error("Failed to load history: \(error.localizedDescription)")
        }
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.chatAdapter?.setTheme(theme)
            self.messageVC.setTheme(theme)
            self.snapToLiveButton.setTheme(theme)
            self.chatInputViewAccessory.setTheme(theme)
            self.stickerInputView.setTheme(theme)
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
        // Return success since chatAdapter is already setup
        guard chatAdapter == nil else {
            return .init(value: ())
        }

        /// Normally this would be done in the session `didSet` observer
        /// however when a property is weak the observer does not get notified
        /// when it's set to nil.
        /// See dicussion at https://stackoverflow.com/a/24317758/1615621
        session.sessionDidEnd = { [weak self] in
            self?.chatAdapter = nil
        }

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

extension ChatViewController: ChatSessionDelegate {
    func chatSession(chatAdapterDidChange chatAdapter: ChatAdapter?) {
        self.chatAdapter = chatAdapter
        self.loadInitialHistory()
        self.refreshStickers()
    }

    func chatSession(pauseStatusDidChange pauseStatus: PauseStatus) {
        switch pauseStatus {
        case .paused:
            // Don't need to do anything
            break
        case .unpaused:
            guard let session = session as? InternalContentSession else {
                log.debug("Resume not necessary when session is nil.")
                return
            }
            session.rankClient?.getUserRank()
        }
    }
}
