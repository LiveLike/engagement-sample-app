//
//  Theme.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-01-18.
//

import UIKit

/**
 An object that defines the look and feel of Widgets and Chat in the Engagement SDK

 You can use the presets or build your own to match your application's style.
 */
@objc(LLTheme)
public class Theme: NSObject {
    // swiftlint:disable function_body_length

    /// Changes the properties of widgets
    public var widgets: Widgets

    /// Changes the body color of Widgets
    @objc public var widgetBodyColor: UIColor
    /// Changes the corner radius of Widgets
    @objc public var widgetCornerRadius: CGFloat

    /// Changes the primary font color of Widgets
    @objc public var widgetFontPrimaryColor: UIColor
    /// Changes the secondary font color of Widgets
    @objc public var widgetFontSecondaryColor: UIColor
    /// Changes the tertiary font color of Widgets
    @objc public var widgetFontTertiaryColor: UIColor

    /// Changes the primary line spacing distance in points
    /// between the bottom of one line fragment and the top of the next.
    @objc public var widgetFontPrimaryLineSpacing: CGFloat
    /// Changes the secondary line spacing distance in points
    /// between the bottom of one line fragment and the top of the next.
    @objc public var widgetFontSecondaryLineSpacing: CGFloat
    /// Changes the tertiary line spacing distance in points
    /// between the bottom of one line fragment and the top of the next.
    @objc public var widgetFontTertiaryLineSpacing: CGFloat

    /// Changes the primary font used by Widgets and Chat
    @objc public var fontPrimary: UIFont
    /// Changes the secondary font used by Widgets and Chat
    @objc public var fontSecondary: UIFont
    /// Changes the tertiary font used by Widgets and Chat
    @objc public var fontTertiary: UIFont

    // MARK: - CHAT

    /// Changes the body color of Chat
    @objc public var chatBodyColor: UIColor
    /// Changes the corner radius of Chat Input
    @objc public var chatCornerRadius: CGFloat
    /// Changes the leading space of chat to the parent view
    @objc public var chatLeadingMargin: CGFloat
    /// Changes the trailing space of chat to the parent view
    @objc public var chatTrailingMargin: CGFloat
    /// Changes the usernames of other users on Chat messages
    
    // MARK: Chat Cell
    @objc public var usernameTextColor: UIColor
    /// Changes the username of the local user's Chat messages
    @objc public var myUsernameTextColor: UIColor
    /// Changes the text color of Chat messages
    @objc public var messageTextColor: UIColor
    /// Changes the font of Chat messages
    @objc public var messageTextFont: UIFont
    /// Changes the background color of Chat bubble
    @objc public var messageBackgroundColor: UIColor
    /// Changes the background color of the Chat bubble when selected
    @objc public var messageSelectedColor: UIColor
    /// Changes the padding of the message within the Chat bubble
    @objc public var messagePadding: CGFloat
    /// Changes the margin of the Chat bubble within the Chat body
    @objc public var messageMargin: CGFloat
    /// Changes the margins of the chat message body
    @objc public var messageMargins: UIEdgeInsets
    /// Changes the chat message width to dynamic or full width
    @objc public var messageDynamicWidth: Bool
    /// Changes the chat message corner radius
    @objc public var messageCornerRadius: CGFloat
    
    // MARK: Chat Reactions
    /// Changes the vertical position of Reactions for each message
    @objc public var messageReactionsVerticalOffset: CGFloat
    /// Changes the horizontal position of the Reactions panel for each message
    @objc public var reactionsPopupHorizontalAlignment: HorizontalAlignment
    /// Changes the horizontal offset of the Reactions panel for each message
    @objc public var reactionsPopupHorizontalOffset: CGFloat
    /// Changes the vertical offset of the Reactions panel for each message
    @objc public var reactionsPopupVerticalOffset: CGFloat
    /// Changes the corner radius of the Reactions popup for each message
    @objc public var reactionsPopupCornerRadius: CGFloat
    /// Changes the background color of the reaction popup
    @objc public var reactionsPopupBackground: UIColor
    /// Changes the color of a selected reaction
    @objc public var reactionsPopupSelectedBackground: UIColor
    /// Changes the image used as a chat reaction hint
    @objc public var reactionsImageHint: UIImage?
    
    // MARK: Chat Cell Borders
    /// Changes the size of the top chat cell border
    @objc public var messageTopBorderHeight: CGFloat
    /// Changes the color of the top chat cell border
    @objc public var messageTopBorderColor: UIColor
    /// Changes the size of the bottom chat cell border
    @objc public var messageBottomBorderHeight: CGFloat
    /// Changes the color of the bottom chat cell border
    @objc public var messageBottomBorderColor: UIColor
    
    // MARK: Chat Cell Image Theme
    /// Chat cell image width
    @objc public var chatImageWidth: CGFloat
    /// Chat cell image height
    @objc public var chatImageHeight: CGFloat
    /// Vertical alignment of the chat cell image
    @objc public var chatImageVerticalAlignment: VerticalAlignment
    /// Chat cell image corner radius
    @objc public var chatImageCornerRadius: CGFloat
    /// Spacing between the cell image and the chat cell content on the right
    @objc public var chatImageTrailingMargin: CGFloat

    // MARK: Chat Input
    /// Changes the color of the Chat input field placeholder text
    @objc public var chatInputPlaceholderTextColor: UIColor
    /// Changes the border color of the Chat input field
    @objc public var chatInputBorderColor: UIColor
    /// Changes the background color of the Chat input field
    @objc public var chatInputBackgroundColor: UIColor
    /// Changes the border width of the Chat input field
    @objc public var chatInputBorderWidth: CGFloat
    /// Changes the left and right insets of the Chat input field
    @objc public var chatInputSideInsets: SideInsets
    /// Changes the tint of the send button on the right hand side of chat input field
    @objc public var chatInputSendButtonTint: UIColor?
    ///Override the send button image for chat. The optimal dimensions are 40x40
    @objc public var chatInputSendButtonImage: UIImage?

    /// Changes the primary color of Chat icons
    @objc public var chatDetailPrimaryColor: UIColor
    /// Changes the secondary color of Chat icons
    @objc public var chatDetailSecondaryColor: UIColor

    /// Changes the font of the chat message timestamp label
    @objc public var chatMessageTimestampFont: UIFont

    /// Changes the text color of the chat message timestamp label
    @objc public var chatMessageTimestampTextColor: UIColor

    /// Changes the distance between the chat message and the timestamp
    @objc public var chatMessageTimestampTopPadding: CGFloat

    /// Changes the color of the loading indicator for chat.
    @objc public var chatLoadingIndicatorColor: UIColor

    // MARK: Chat Sticker Keyboard
    /// Changes the primary color of the sticker keyboard
    @objc public var chatStickerKeyboardPrimaryColor: UIColor
    /// Changes the secondary color of the sticker keyboard
    @objc public var chatStickerKeyboardSecondaryColor: UIColor
    /// Change the chat sticker keyboard icon in `.normal` state
    @objc public var chatStickerKeyboardIcon: UIImage
    /// Changes the tint color of the sticker keyboard icon in `.normal` state
    @objc public var chatStickerKeyboardIconTint: UIColor
    /// Change the chat sticker keyboard icon in `.selected` state
    @objc public var chatStickerKeyboardIconSelected: UIImage
    /// Changes the tint color of the sticker keyboard icon in `.selected` state
    @objc public var chatStickerKeyboardIconSelectedTint: UIColor

    // MARK: - Widget

    /// Changes the colors to highlight a neutral option
    @available(*, deprecated, message: "Use theme.widgets.<poll/quiz/prediction>.unselectedOption instead.")
    @objc public var neutralOptionColors: ChoiceWidgetOptionColors = ChoiceWidgetOptionColors(
        borderColor: .clear,
        barGradientLeft: UIColor(white: 1, alpha: 0.2),
        barGradientRight: UIColor(white: 1, alpha: 0.2)
    )

    /// Changes the colors to highlight a correct option
    @available(*, deprecated, message: "Use theme.widgets.<poll/quiz/prediction>.correctOption instead.")
    @objc public var correctOptionColors: ChoiceWidgetOptionColors = ChoiceWidgetOptionColors(
        borderColor: #colorLiteral(red: 0, green: 0.7843137255, blue: 0.2352941176, alpha: 1),
        barGradientLeft: #colorLiteral(red: 0.2588235294, green: 0.5764705882, blue: 0.1294117647, alpha: 1),
        barGradientRight: #colorLiteral(red: 0.5058823529, green: 0.7921568627, blue: 0, alpha: 1)
    )

    /// Changes the colors to highlight an incorrect option
    @available(*, deprecated, message: "Use theme.widgets.<poll/quiz/prediction>.incorrect instead.")
    @objc public var incorrectOptionColors: ChoiceWidgetOptionColors = ChoiceWidgetOptionColors(
        borderColor: #colorLiteral(red: 0.8156862745, green: 0.007843137255, blue: 0.1058823529, alpha: 1),
        barGradientLeft: #colorLiteral(red: 0.8156862745, green: 0.007843137255, blue: 0.1058823529, alpha: 1),
        barGradientRight: #colorLiteral(red: 0.862745098, green: 0, blue: 0.1568627451, alpha: 1)
    )

    /// Changes whether widget titles should be uppercased
    @objc public var uppercaseTitleText: Bool

    /// Changes whether widget option text should be uppercased
    @objc public var uppercaseOptionText: Bool

    /// Changes the properties of the poll widget
    @available(*, deprecated, message: "Use theme.widgets.poll instead.")
    public var pollWidget: PollWidgetTheme = PollWidgetTheme(
        titleGradientLeft: #colorLiteral(red: 0.1882352941, green: 0.137254902, blue: 0.6823529412, alpha: 1),
        titleGradientRight: #colorLiteral(red: 0.7843137255, green: 0.3921568627, blue: 0.7843137255, alpha: 1),
        selectedColors: ChoiceWidgetOptionColors(
            borderColor: #colorLiteral(red: 0.7843137255, green: 0.4274509804, blue: 0.8431372549, alpha: 1),
            barGradientLeft: #colorLiteral(red: 0.5882352941, green: 0.3137254902, blue: 0.7450980392, alpha: 1),
            barGradientRight: #colorLiteral(red: 0.7843137255, green: 0.3921568627, blue: 0.7843137255, alpha: 1)
        )
    )

    /// Changes the properties of the quiz widget
    @available(*, deprecated, message: "User theme.widgets.quiz isntead.")
    public var quizWidget: QuizWidgetTheme = QuizWidgetTheme(
        titleGradientLeft: #colorLiteral(red: 0.968627451, green: 0.4196078431, blue: 0.1098039216, alpha: 1),
        titleGradientRight: #colorLiteral(red: 1, green: 0.7058823529, blue: 0, alpha: 1),
        optionSelectBorderColor: #colorLiteral(red: 1, green: 0.7843137255, blue: 0, alpha: 1)
    )

    /// Changes the properties of the prediction widget
    @available(*, deprecated, message: "Use theme.widgets.prediction instead.")
    public var predictionWidget: PredictionWidgetTheme = PredictionWidgetTheme(
        titleGradientLeft: #colorLiteral(red: 0, green: 0.1960784314, blue: 0.3921568627, alpha: 1),
        titleGradientRight: #colorLiteral(red: 0, green: 0.5882352941, blue: 0.7843137255, alpha: 1),
        optionSelectBorderColor: #colorLiteral(red: 0, green: 0.7058823529, blue: 0.7843137255, alpha: 1),
        optionGradientColors: ChoiceWidgetOptionColors(
            borderColor: #colorLiteral(red: 0, green: 0.7058823529, blue: 0.7843137255, alpha: 1),
            barGradientLeft: #colorLiteral(red: 0.1568627451, green: 0.3921568627, blue: 0.5490196078, alpha: 1),
            barGradientRight: #colorLiteral(red: 0, green: 0.7058823529, blue: 0.7843137255, alpha: 1)
        ),
        lottieAnimationOnTimerCompleteFilepath: [
            Bundle(for: EngagementSDK.self).path(forResource: "stay_tuned_1", ofType: "json"),
            Bundle(for: EngagementSDK.self).path(forResource: "stay_tuned_2", ofType: "json")
        ].compactMap({ $0 })
    )

    /// Changes the properties of the alert widget
    @available(*, deprecated, message: "Use theme.widgets.alert instead.")
    public var alertWidget: AlertWidgetTheme = AlertWidgetTheme(
        titleGradientLeft: #colorLiteral(red: 0.6235294118, green: 0.01568627451, blue: 0.1058823529, alpha: 1),
        titleGradientRight: #colorLiteral(red: 0.9607843137, green: 0.3176470588, blue: 0.3725490196, alpha: 1),
        linkBackgroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.05)
    )

    /// Changes the properties of the image slider widget
    @objc public var imageSlider: ImageSliderTheme

    /// Changes the properties of the cheer meter widget
    @objc public var cheerMeter: CheerMeterTheme

    /// Changes the border width of a selected option
    @objc public var selectedOptionBorderWidth: CGFloat

    /// Changes the border width of an unselected option
    @objc public var unselectedOptionBorderWidth: CGFloat

    /// Changes the text color of a selected option
    @objc public var selectedOptionTextColor: UIColor

    /// Changes the spacing between each option
    @objc public var interOptionSpacing: CGFloat

    /// Changes the spacing between the title and body panels
    @objc public var titleBodySpacing: CGFloat

    /// Changes the corner radius of a widget option when unselected
    @objc public var unselectedOptionCornerRadius: CGFloat

    @objc public var choiceWidgetTitleMargins: UIEdgeInsets

    // MARK: - Gamification

    /// Changes the color of the Gamification Popup Headline
    @objc public var popupTitleColor: UIColor

    /// Changes the font of the Gamification Popup Headline
    @objc public var popupTitleFont: UIFont

    /// Changes the color of the Gamification Popup Message
    @objc public var popupMessageColor: UIColor

    /// Changes the font of the Gamification Popup Message
    @objc public var popupMessageFont: UIFont

    /// Changes the color of the Gamification Popup Action Button
    @objc public var popupActionButtonBg: UIColor

    /// Changes the color of the Gamification Popup Action Button Title
    @objc public var popupActionButtonTitleColor: UIColor

    /// Changes the color of the Rank background
    @objc public var rankBackgroundColor: UIColor

    /// Changes the color of the Rank Text Color
    @objc public var rankTextColor: UIColor

    /// Changes the font of the Rank Text
    @objc public var rankTextFont: UIFont

    // MARK: - Chat Reactions

    /// Collection of theme properties for chat reactions
    @objc public var chatReactions: ChatReactionsTheme

    @available(*, deprecated, message: "Use theme.lottieFilepaths.win instead.")
    @objc public var filepathsForLottieWinningAnimations: [String] = Theme.LottieFilepaths.defaultWin

    @available(*, deprecated, message: "Use theme.lottieFilepaths.lose instead.")
    @objc public var filepathsForLottieLosingAnimations: [String] = Theme.LottieFilepaths.defaultLose

    @available(*, deprecated, message: "Use theme.lottieFilepaths.tie instead.")
    public var filepathsForLottieTieAnimations: [String] = Theme.LottieFilepaths.defaultTie

    @available(*, deprecated, message: "Use theme.lottieFilepaths.timer instead.")
    public var filepathsForWidgetTimerLottieAnimation: String = Bundle(for: EngagementSDK.self).path(forResource: "timer", ofType: "json")!

    /// Set a custom view to be shown when a chat room has 0 messages.
    /// The constraints on this view will fill the container width and height.
    /// The view will be hidden when the first message is received in the chat room.
    @objc public var emptyChatCustomView: UIView?

    /// Changes the filepath pointing to the lottie animation for different scenarios
    public var lottieFilepaths: LottieFilepaths

    /// Defaults
    @objc public override init() {

        self.widgets = Widgets()

        fontPrimary = UIFont.preferredFont(forTextStyle: .subheadline)
        fontSecondary = UIFont.preferredFont(forTextStyle: .caption1).livelike_bold()
        fontTertiary = UIFont.preferredFont(forTextStyle: .headline).livelike_bold()
        
        widgetBodyColor = UIColor(rInt: 0, gInt: 0, bInt: 0, alpha: 1)
        widgetFontPrimaryColor = .white
        widgetFontSecondaryColor = .white
        widgetFontTertiaryColor = .white
        widgetCornerRadius = 6
        unselectedOptionCornerRadius = 0
        choiceWidgetTitleMargins = UIEdgeInsets(top: 10, left: 16, bottom: -10, right: 0)

        widgetFontPrimaryLineSpacing = 0
        widgetFontSecondaryLineSpacing = 0
        widgetFontTertiaryLineSpacing = 0

        chatBodyColor = UIColor(rInt: 35, gInt: 40, bInt: 45)
        chatDetailPrimaryColor = UIColor(white: 1, alpha: 0.9)
        chatDetailSecondaryColor = UIColor(rInt: 35, gInt: 40, bInt: 45)
        chatStickerKeyboardPrimaryColor = UIColor(rInt: 20, gInt: 20, bInt: 20)
        chatStickerKeyboardSecondaryColor = UIColor(rInt: 40, gInt: 40, bInt: 40)
        chatStickerKeyboardIcon = UIImage(named: "chat_emoji_button", in: Bundle(for: Theme.self), compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        chatStickerKeyboardIconSelected = UIImage(named: "chat_keyboard_button", in: Bundle(for: Theme.self), compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        chatStickerKeyboardIconTint = .white
        chatStickerKeyboardIconSelectedTint = .white
        
        chatCornerRadius = 12
        chatLeadingMargin = 16
        chatTrailingMargin = 16

        usernameTextColor = UIColor(white: 1, alpha: 0.4)
        myUsernameTextColor = UIColor(rInt: 50, gInt: 200, bInt: 250)

        messageTextColor = UIColor(white: 1, alpha: 0.9)
        messageTextFont = UIFont.systemFont(ofSize: 17.0)
        messageBackgroundColor = UIColor(white: 0, alpha: 0.4)
        messageSelectedColor = UIColor(rInt: 100, gInt: 100, bInt: 100, alpha: 0.4)
        messagePadding = 16
        messageMargin = 0
        messageMargins = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 16)
        messageDynamicWidth = true
        messageCornerRadius = 12
        messageTopBorderHeight = 0
        messageTopBorderColor = .clear
        messageBottomBorderHeight = 0
        messageBottomBorderColor = .clear
        messageReactionsVerticalOffset = 3.0
        reactionsPopupHorizontalAlignment = .left
        reactionsPopupHorizontalOffset = 16.0
        reactionsPopupVerticalOffset = 0.0
        reactionsPopupCornerRadius = 12.0
        reactionsPopupBackground = UIColor(white: 1, alpha: 0.9)
        reactionsPopupSelectedBackground = UIColor(rInt: 0/255, gInt: 0/255, bInt: 0/255, alpha: 0.2)
        reactionsImageHint = UIImage(named: "chatReactionDefault", in: Bundle(for: Theme.self), compatibleWith: nil)

        chatInputPlaceholderTextColor = UIColor.white
        chatInputBorderColor = UIColor(white: 1, alpha: 0.2)
        chatInputBackgroundColor = UIColor(white: 0, alpha: 0.4)
        chatInputBorderWidth = 1
        chatInputSideInsets = .zero

        uppercaseTitleText = true
        uppercaseOptionText = false

        imageSlider = ImageSliderTheme()

        cheerMeter = CheerMeterTheme()

        selectedOptionBorderWidth = 2.0
        unselectedOptionBorderWidth = 2.0
        selectedOptionTextColor = .white
        interOptionSpacing = 0.0
        titleBodySpacing = 0.0

        // MARK: Gamification Init
        popupTitleColor = .white
        popupTitleFont = UIFont.preferredFont(forTextStyle: .callout).livelike_bold()
        popupMessageColor = .white
        popupMessageFont = UIFont.preferredFont(forTextStyle: .subheadline)
        popupActionButtonBg = .purple
        popupActionButtonTitleColor = .white
        rankBackgroundColor = .purple
        rankTextColor = .white
        rankTextFont = UIFont.preferredFont(forTextStyle: .caption2)

        chatReactions = ChatReactionsTheme(panelCountsColor: .black,
                                           displayCountsColor: .white)
        
        // MARK: Chat Cell Image Init
        chatImageWidth = 32.0
        chatImageHeight = 32.0
        chatImageVerticalAlignment = .center
        chatImageCornerRadius = chatImageHeight / 2
        chatImageTrailingMargin = 10.0

        chatMessageTimestampFont = UIFont.systemFont(ofSize: 8)
        chatMessageTimestampTextColor = UIColor(white: 1, alpha: 0.4)
        chatMessageTimestampTopPadding = 6.0

        chatLoadingIndicatorColor = .white

        lottieFilepaths = LottieFilepaths(
            predictionTimerComplete: [
                Bundle(for: EngagementSDK.self).path(forResource: "stay_tuned_1", ofType: "json")!,
                Bundle(for: EngagementSDK.self).path(forResource: "stay_tuned_2", ofType: "json")!
            ],
            win: LottieFilepaths.defaultWin,
            lose: LottieFilepaths.defaultLose,
            tie: LottieFilepaths.defaultTie,
            timer: Bundle(for: EngagementSDK.self).path(forResource: "timer", ofType: "json")!
        )
    }

    public enum Background {
        //swiftlint:disable nesting
        public struct Gradient {
            public var colors: [UIColor]
            public var start: CGPoint
            public var end: CGPoint

            public init(colors: [UIColor]) {
                self.colors = colors
                start = CGPoint(x: 0, y: 0.5)
                end = CGPoint(x: 1, y: 0.5)
            }

            public init(colors: [UIColor], start: CGPoint, end: CGPoint) {
                self.colors = colors
                self.start = start
                self.end = end
            }
        }

        case gradient(gradient: Gradient)
        case fill(color: UIColor)
    }

    public struct LottieFilepaths {
        public var predictionTimerComplete: [String]
        /*
         Override the default winning animations by providing the full path of your custom lottie json.
         If more than 1 animation is provided they will be played in random order.
        */
        public var win: [String]

        /*
         Override the default losing animations by providing the full path of your custom lottie json.
         If more than 1 animation is provided they will be played in random order.
         */
        public var lose: [String]

        /*
         Override the default losing animations by providing the full path of your custom lottie json.
         If more than 1 animation is provided they will be played in random order.
        */
        public var tie: [String]

        /// Overrides the timer animation for widgets
        public var timer: String

        static var defaultWin: [String] = {
            let bundle = Bundle(for: EngagementSDK.self)
            return [
                bundle.path(forResource: "confetti-1", ofType: "json")!,
                bundle.path(forResource: "confetti-2", ofType: "json")!,
                bundle.path(forResource: "confetti-3", ofType: "json")!,
                bundle.path(forResource: "confetti-4", ofType: "json")!,
            ]
        }()

        func randomWin() -> String {
            if let randomFilepath = win.randomElement() {
                return randomFilepath
            } else {
                return LottieFilepaths.defaultWin.randomElement()!
            }
        }

        static var defaultLose: [String] = {
            let bundle = Bundle(for: EngagementSDK.self)
            return [
                bundle.path(forResource: "wrong-1", ofType: "json")!,
                bundle.path(forResource: "wrong-2", ofType: "json")!,
                bundle.path(forResource: "wrong-3", ofType: "json")!,
                bundle.path(forResource: "wrong-4", ofType: "json")!,
            ]
        }()

        func randomLose() -> String {
            if let randomFilepath = lose.randomElement() {
                return randomFilepath
            } else {
                return LottieFilepaths.defaultLose.randomElement()!
            }
        }

        static var defaultTie: [String] = {
            let bundle = Bundle(for: EngagementSDK.self)
            return [
                bundle.path(forResource: "draw-1", ofType: "json")!,
            ]
        }()

        func randomTie() -> String {
            if let randomFilepath = tie.randomElement() {
                return randomFilepath
            } else {
                return LottieFilepaths.defaultTie.randomElement()!
            }
        }
    }

    public struct Widgets {
        /// Changes the properties of the poll widget
        public var poll: ChoiceWidget
        /// Changes the properties of the quiz widget
        public var quiz: ChoiceWidget
        /// Changes the properties of the prediction widget
        public var prediction: ChoiceWidget
        /// Changes the properties of the alert widget
        public var alert: AlertWidget

        public init(
            poll: Theme.ChoiceWidget,
            quiz: Theme.ChoiceWidget,
            prediction: Theme.ChoiceWidget,
            alert: Theme.AlertWidget
        ) {
            self.poll = poll
            self.quiz = quiz
            self.prediction = prediction
            self.alert = alert
        }

        /// Defaults
        internal init() {
            let widgetOptionTextFont = UIFont.preferredFont(forTextStyle: .subheadline)
            let widgetTitleFont = UIFont.preferredFont(forTextStyle: .caption1).livelike_bold()
            let widgetCornerRadius: CGFloat = 6
            let widgetOptionCornerRadius: CGFloat = 6
            let widgetTextColor: UIColor = .white

            let optionContainer = Theme.ChoiceWidget.Option(
                container: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 2,
                    cornerRadii: CornerRadii(all: widgetOptionCornerRadius)
                ),
                description: Text(
                    color: widgetTextColor,
                    font: widgetOptionTextFont
                ),
                percentage: Text(
                    color: widgetTextColor,
                    font: UIFont.preferredFont(forTextStyle: .headline).livelike_bold()
                ),
                progressBar: ProgressBar(
                    background: .fill(color: .clear),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 3)
                )
            )

            let correctOptionContainer: Theme.ChoiceWidget.Option = {
                var option = optionContainer
                option.container.borderColor = #colorLiteral(red: 0, green: 0.7843137255, blue: 0.2352941176, alpha: 1)
                option.progressBar.background = .gradient(
                    gradient: Background.Gradient(
                        colors: [#colorLiteral(red: 0.2588235294, green: 0.5764705882, blue: 0.1294117647, alpha: 1), #colorLiteral(red: 0.5058823529, green: 0.7921568627, blue: 0, alpha: 1)],
                        start: CGPoint(x: 0, y: 0.5),
                        end: CGPoint(x: 1, y: 0.5)
                    )
                )
                return option
            }()

            let incorrectOptionContainer: Theme.ChoiceWidget.Option = {
                var option = optionContainer
                option.container.borderColor = #colorLiteral(red: 0.8156862745, green: 0.007843137255, blue: 0.1058823529, alpha: 1)
                option.progressBar.background = .gradient(
                    gradient: Background.Gradient(
                        colors: [#colorLiteral(red: 0.8156862745, green: 0.007843137255, blue: 0.1058823529, alpha: 1), #colorLiteral(red: 0.862745098, green: 0, blue: 0.1568627451, alpha: 1)],
                        start: CGPoint(x: 0, y: 0.5),
                        end: CGPoint(x: 1, y: 0.5)
                    )
                )
                return option
            }()

            let unselectedOptionContainer: Theme.ChoiceWidget.Option = {
                var option = optionContainer
                option.container.borderColor = .clear
                option.progressBar.background = .fill(color: UIColor(white: 1, alpha: 0.2))
                return option
            }()

            poll = ChoiceWidget(
                main: Container(
                    background: .fill(color: .clear),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: widgetCornerRadius)
                ),
                header: Container(
                    background: .gradient(
                        gradient: Background.Gradient(
                            colors: [#colorLiteral(red: 0.1882352941, green: 0.137254902, blue: 0.6823529412, alpha: 1), #colorLiteral(red: 0.7843137255, green: 0.3921568627, blue: 0.7843137255, alpha: 1)],
                            start: CGPoint(x: 0, y: 0.5),
                            end: CGPoint(x: 1, y: 0.5)
                        )
                    ),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 0)
                ),
                body: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 0)
                ),
                title: Text(
                    color: .white,
                    font: widgetTitleFont
                ),
                correctOption: correctOptionContainer,
                incorrectOption: incorrectOptionContainer,
                selectedOption: {
                    var option = optionContainer
                    option.container.borderColor = #colorLiteral(red: 0.7843137255, green: 0.4274509804, blue: 0.8431372549, alpha: 1)
                    option.progressBar.background = .gradient(
                        gradient: Background.Gradient(
                            colors: [#colorLiteral(red: 0.5882352941, green: 0.3137254902, blue: 0.7450980392, alpha: 1), #colorLiteral(red: 0.7843137255, green: 0.3921568627, blue: 0.7843137255, alpha: 1)],
                            start: CGPoint(x: 0, y: 0.5),
                            end: CGPoint(x: 1, y: 0.5)
                        )
                    )
                    return option
                }(),
                unselectedOption: unselectedOptionContainer
            )

            quiz = ChoiceWidget(
                main: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: widgetCornerRadius)
                ),
                header: Container(
                    background: .gradient(
                        gradient: Background.Gradient(
                            colors: [#colorLiteral(red: 0.968627451, green: 0.4196078431, blue: 0.1098039216, alpha: 1), #colorLiteral(red: 1, green: 0.7058823529, blue: 0, alpha: 1)],
                            start: CGPoint(x: 0, y: 0.5),
                            end: CGPoint(x: 1, y: 0.5)
                        )
                    ),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 0)
                ),
                body: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 0)
                ),
                title: Text(
                    color: .white,
                    font: widgetTitleFont
                ),
                correctOption: correctOptionContainer,
                incorrectOption: incorrectOptionContainer,
                selectedOption: {
                    var option = optionContainer
                    option.container.borderColor = #colorLiteral(red: 1, green: 0.7843137255, blue: 0, alpha: 1)
                    return option
                }(),
                unselectedOption: unselectedOptionContainer
            )

            prediction = ChoiceWidget(
                main: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: widgetCornerRadius)
                ),
                header: Container(
                    background: .gradient(
                        gradient: Background.Gradient(
                            colors: [#colorLiteral(red: 0, green: 0.1960784314, blue: 0.3921568627, alpha: 1), #colorLiteral(red: 0, green: 0.5882352941, blue: 0.7843137255, alpha: 1)],
                            start: CGPoint(x: 0, y: 0.5),
                            end: CGPoint(x: 1, y: 0.5)
                        )
                    ),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 0)
                ),
                body: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: 0)
                ),
                title: Text(
                    color: .white,
                    font: widgetTitleFont
                ),
                correctOption: correctOptionContainer,
                incorrectOption: incorrectOptionContainer,
                selectedOption: {
                    var option = optionContainer
                    option.container.borderColor = #colorLiteral(red: 0, green: 0.7058823529, blue: 0.7843137255, alpha: 1)
                    option.progressBar.background = .gradient(
                        gradient: Background.Gradient(
                            colors: [#colorLiteral(red: 0.1568627451, green: 0.3921568627, blue: 0.5490196078, alpha: 1), #colorLiteral(red: 0, green: 0.7058823529, blue: 0.7843137255, alpha: 1)],
                            start: CGPoint(x: 0, y: 0.5),
                            end: CGPoint(x: 1, y: 0.5)
                        )
                    )
                    return option
                }(),
                unselectedOption: unselectedOptionContainer
            )

            alert = AlertWidget(
                main: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: CornerRadii(all: widgetCornerRadius)
                ),
                header: Container(
                    background: .gradient(
                        gradient: Background.Gradient(
                            colors: [#colorLiteral(red: 0.6235294118, green: 0.01568627451, blue: 0.1058823529, alpha: 1), #colorLiteral(red: 0.9607843137, green: 0.3176470588, blue: 0.3725490196, alpha: 1)],
                            start: CGPoint(x: 0, y: 0.5),
                            end: CGPoint(x: 1, y: 0.5)
                        )
                    ),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: .zero
                ),
                title: Text(
                    color: widgetTextColor,
                    font: widgetTitleFont
                ),
                body: Container(
                    background: .fill(color: .black),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: .zero
                ),
                description: Text(
                    color: widgetTextColor,
                    font: widgetOptionTextFont
                ),
                footer: Container(
                    background: .fill(color: #colorLiteral(red: 0.08857408911, green: 0.08857408911, blue: 0.08857408911, alpha: 1)),
                    borderColor: .clear,
                    borderWidth: 0,
                    cornerRadii: .zero
                ),
                link: Text(
                    color: widgetTextColor,
                    font: widgetTitleFont
                )
            )
        }
    }
}

public extension Theme {
    // MARK: - Presets

    /// A Theme preset that works well as an overlay over video
    static var overlay: Theme = {
        var theme = Theme()
        theme.chatBodyColor = .clear
        theme.chatDetailSecondaryColor = .black
        return theme
    }()

    /// A Theme preset that resembles an applications 'Dark Mode'. This is the default theme.
    static var dark = Theme()
}

@objc public enum VerticalAlignment: Int {
    case top, center, bottom
}
@objc public enum HorizontalAlignment: Int {
    case left, center, right
}
