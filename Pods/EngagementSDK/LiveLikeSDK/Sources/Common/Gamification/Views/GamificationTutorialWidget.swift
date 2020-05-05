//
//  GamificationTutorialWidget.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/2/19.
//

import UIKit

/// Wraps GamificationModal as a WidgetController to be presented like a widget
class GamificationTutorialWidget: WidgetController {
    var widgetTitle: String? = "EngagementSDK.gamification.TutorialWidget.title".localized()
    private let widgetMessage: String = "EngagementSDK.gamification.TutorialWidget.message".localized()

    var id: String = ""

    var kind = WidgetKind.gamification
    let interactionTimeInterval: TimeInterval? = nil

    weak var delegate: WidgetEvents?

    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
    }
    
    var coreWidgetView: CoreWidgetView = CoreWidgetView()

    var dismissSwipeableView: UIView {
        return self.view
    }

    var correctOptions: Set<WidgetOption>?

    var options: Set<WidgetOption>?

    var customData: String?
    
    private var gamificationModal: GamificationModal!
    private var rewardsView: RewardsView!
    private let awards: AwardsViewModel
    private var eventRecorder: EventRecorder
    private var timeTutorialStarted: Date = Date()

    init(theme: Theme, awards: AwardsViewModel, eventRecorder: EventRecorder) {
        self.awards = awards
        self.eventRecorder = eventRecorder
        super.init(nibName: nil, bundle: nil)

        let pointsAndBadgeProgress = TutorialPointsAndBadgeProgress()
        pointsAndBadgeProgress.translatesAutoresizingMaskIntoConstraints = false
        pointsAndBadgeProgress.setTheme(theme)

        rewardsView = pointsAndBadgeProgress
        gamificationModal = GamificationModal(title: widgetTitle,
                                              message: widgetMessage,
                                              progressionMeter: pointsAndBadgeProgress,
                                              theme: theme,
                                              graphicLottieAnimation: "emoji-happy")
        self.customData = awards.customData
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(coreWidgetView)

        gamificationModal.translatesAutoresizingMaskIntoConstraints = false

        coreWidgetView.headerView = nil
        coreWidgetView.contentView = gamificationModal
        coreWidgetView.footerView = nil

        gamificationModal.heightAnchor.constraint(equalToConstant: 203).isActive = true
    }

    func start() {
        rewardsView.apply(viewModel: awards, animated: true)
        delay(10) { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .timeout))
        }
    }

    func willDismiss(dismissAction: DismissAction) {
        let timeSinceTutorialStarted = Date().timeIntervalSince(timeTutorialStarted)

        var completionType: AnalyticsEvent.GamificationTutorialCompletionType
        switch dismissAction {
        case .complete:
            completionType = .dismiss(secondsSinceStart: timeSinceTutorialStarted)
        case .swipe:
            completionType = .dismiss(secondsSinceStart: timeSinceTutorialStarted)
        case .timeout:
            completionType = .timeout
        default:
            log.verbose("Encountered unhalded dismiss action from gamification tutorial widget.")
            return
        }

        eventRecorder.record(.pointsTutorialCompleted(completionType: completionType))
    }
}

extension AnalyticsEvent {
    enum GamificationTutorialCompletionType {
        case dismiss(secondsSinceStart: TimeInterval)
        case timeout

        var asString: String {
            switch self {
            case .dismiss:
                return "Dismiss"
            case .timeout:
                return "Time Completed"
            }
        }
    }

    static func pointsTutorialCompleted(completionType: GamificationTutorialCompletionType) -> AnalyticsEvent {
        var dismissSecondsSinceStart: TimeInterval
        if case let GamificationTutorialCompletionType.dismiss(secondsSinceStart) = completionType {
            dismissSecondsSinceStart = secondsSinceStart
        } else {
            dismissSecondsSinceStart = 0
        }
        return AnalyticsEvent(name: "Points Tutorial Completed",
                              data: [.completionType: completionType.asString,
                                     .dismissSecondsSinceStart: dismissSecondsSinceStart])
    }
}
