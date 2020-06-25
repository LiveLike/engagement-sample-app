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

    var chatSession: InternalChatSessionProtocol?
    /// The current Chat Session being displayed if any
    public var currentChatSession: ChatSession? {
        return self.chatSession
    }
    
    /// Removes the current chat session if there is one set.
    public func clearChatSession() {
        self.chatSession?.removeInternalDelegate(self)
        self.chatSession = nil
        self.chatAdapter = nil
        self.stickerPacks = []
    }
    
    /// Sets the chat session to be displayed.
    /// Replaces the current chat session if there is one set.
    public func setChatSession(_ chatSession: ChatSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.clearChatSession()
            
            guard let chatSession = chatSession as? InternalChatSessionProtocol else { return }
            self.chatSession = chatSession
            self.messageVC.chatSession = chatSession
            
            chatSession.stickerRepository.getStickerPacks { [weak self] result in
                guard let self = self else { return}
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let stickerPacks):
                        self.stickerPacks = stickerPacks
                    case .failure(let error):
                        log.error("Failed to get sticker packs with error: \(error)")
                    }

                    self.stickerInputView.stickerPacks = self.recentlyUsedStickerPacks + self.stickerPacks
                    self.chatInputViewAccessory.keyboardToggleButton.isHidden = !self.doStickersExist(stickerPacks: self.stickerPacks)
                    
                    let factory = MessageViewModelFactory(
                        stickerPacks: self.stickerPacks,
                        channel: "",
                        reactionsFactory: chatSession.reactionsViewModelFactory,
                        mediaRepository: EngagementSDK.mediaRepository
                    )

                    let adapter = ChatAdapter(
                        messageViewModelFactory: factory,
                        eventRecorder: chatSession.eventRecorder,
                        blockList: chatSession.blockList,
                        chatSession: chatSession
                    )
                    
                    chatSession.addInternalDelegate(self)
                    
                    self.chatAdapter = adapter
                    self.chatSession(chatSession, didRecieveMessageHistory: chatSession.messages)
                }
            }
        }
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

            sessionImpl.chatDelegate = self
            eventRecorder = sessionImpl.eventRecorder
            superPropertyRecorder = sessionImpl.superPropertyRecorder
            peoplePropertyRecorder = sessionImpl.peoplePropertyRecorder

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
    public var messageTimestampFormatter: TimestampFormatter? = { date in
        let dateFormatter = DateFormatter()
        dateFormatter.amSymbol = "am"
        dateFormatter.pmSymbol = "pm"
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d hh:mm")
        return dateFormatter.string(from: date)
    }

    /// Determines whether the user is able to post images into chat
    public var shouldSupportChatImagePosting: Bool = true {
        didSet {
            self.chatInputViewAccessory.supportExternalImages = shouldSupportChatImagePosting
        }
    }
    
    /// Determines whether the user is able to post images into chat
    public var shouldDisplayDebugVideoTime: Bool = false
    
    var stickerPacks: [StickerPack] = []

    // MARK: Internal Properties

    lazy var messageVC: MessageViewController = {
        let messagesVC = MessageViewController()
        messagesVC.setTheme(theme)
        messagesVC.chatAdapter = chatAdapter
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
    
    var recentlyUsedStickers = LimitedArray<Sticker>(maxSize: 30)

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
    public override func willTransition(to newCollection: UITraitCollection,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // Save the visible row position
            self?.isRotating = true
            self?.chatAdapter?.orientationWillChange()
        }, completion: { [weak self] _ in
            // Scroll to the saved position prior to screen rotate
            self?.chatAdapter?.orientationDidChange()
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
        guard let chatSession = chatSession else {
            return
        }

        let clientMessage = ClientMessage(
            message: message.message,
            imageURL: message.imageURL,
            imageSize: message.imageSize
        )
        chatSession.sendMessage(clientMessage).then { [weak self] chatMessageID in
    
            guard let self = self else { return }
            guard let messageText = message.message else { return }
            
            let stickerIDs = messageText.stickerIDs
            let indices = ChatSentMessageProperties.calculateStickerIndices(stickerIDs: stickerIDs, stickers: self.stickerPacks)
            let sentProperties = ChatSentMessageProperties(
                characterCount: messageText.count,
                messageId: chatMessageID.asString,
                stickerIDs: stickerIDs,
                stickerCount: stickerIDs.count,
                stickerIndices: indices,
                hasExternalImage: message.imageURL != nil
            )
            self.eventRecorder?.record(.chatMessageSent(properties: sentProperties))

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

    func loadMoreHistory(){
        guard let chatSession = chatSession else { return }
        messageVC.isLoading(true)
        
        firstly {
            chatSession.loadPreviousMessagesFromHistory()
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

extension ChatViewController: InternalChatSessionDelegate {
    func chatSession(_ chatSession: ChatSession, didRecieveError error: Error) {
        
    }
    
    public func chatSession(_ chatSession: ChatSession, didRecieveNewMessage message: ChatMessage) {
        DispatchQueue.main.async {
            self.chatAdapter?.publish(newMessage: message)
        }
    }
    
    public func chatSession(_ chatSession: ChatSession, didRecieveMessageHistory messages: [ChatMessage]) {
        DispatchQueue.main.async {
            self.chatAdapter?.publish(messagesFromHistory: messages)
        }
    }
    
    public func chatSession(_ chatSession: ChatSession, didRecieveMessageUpdate message: ChatMessage) {
        DispatchQueue.main.async {
            self.chatAdapter?.publish(messageUpdated: message)
        }
    }
    
    public func chatSession(_ chatSession: ChatSession, didRecieveMessageDeleted messageID: ChatMessageID) {
        DispatchQueue.main.async {
            self.chatAdapter?.deleteMessage(messageId: messageID)
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

extension ChatViewController: ContentSessionChatDelegate {
    func chatSession(chatSessionDidChange chatSession: InternalChatSessionProtocol?) {
        if let chatSession = chatSession {
            self.setChatSession(chatSession)
        } else {
            self.clearChatSession()
        }
    }

    func chatSession(pauseStatusDidChange pauseStatus: PauseStatus) {
        switch pauseStatus {
        case .paused:
            self.chatAdapter?.didInteractWithMessageView = false // reset user interaction when paused
        case .unpaused:
            guard let session = session as? InternalContentSession else {
                log.debug("Resume not necessary when session is nil.")
                return
            }
            session.rankClient?.getUserRank()
        }
    }
}
