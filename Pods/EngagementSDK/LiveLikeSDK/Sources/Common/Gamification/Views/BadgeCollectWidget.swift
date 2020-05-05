//
//  BadgeCollectWidget.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/9/19.
//

import UIKit

class BadgeCollectWidget: WidgetController {
    private let message: String = "EngagementSDK.gamification.BadgeCollectWidget.message".localized()
    private let buttonText: String = "EngagementSDK.gamification.BadgeCollectWidget.button".localized()

    var id: String = ""

    var kind = WidgetKind.gamification
    let interactionTimeInterval: TimeInterval? = nil

    weak var delegate: WidgetEvents?
    var dismissSwipeableView: UIView {
        return self.view
    }

    var height: CGFloat {
        return coreWidgetView.bounds.height + 32
    }
    
    var coreWidgetView: CoreWidgetView = CoreWidgetView()
    var widgetTitle: String?
    var correctOptions: Set<WidgetOption>?
    var options: Set<WidgetOption>?
    var customData: String?

    private let badgeViewModel: BadgeViewModel
    private var gamificationModal: GamificationModal!
    private let timeout: TimeInterval = 20

    private let eventRecorder: EventRecorder

    init(theme: Theme, badgeToCollect badge: BadgeViewModel, eventRecorder: EventRecorder) {
        self.eventRecorder = eventRecorder
        self.badgeViewModel = badge
        self.widgetTitle = "Badge Collect"
        super.init(nibName: nil, bundle: nil)

        gamificationModal = GamificationModal(title: badge.name,
                                              message: message,
                                              progressionMeter: nil,
                                              theme: theme,
                                              graphicImage: badge.image,
                                              actionButtonTitle: buttonText,
                                              actionButtonHandler: { [weak self] in
                                                self?.handleActionButton()
                                              })
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

        delay(0.2){ [weak self] in
            self?.gamificationModal.animateGraphic()
        }
    }

    private func handleActionButton() {
        self.badgeViewModel.collect()
        eventRecorder.record(.badgeCollected(badgeViewModel.innerBadge))
        gamificationModal.playBadgeCollectAnimation().then { _ in
            self.delegate?.actionHandler(event: .dismiss(action: .complete))
        }.catch { error in
            log.error(error.localizedDescription)
            self.delegate?.actionHandler(event: .dismiss(action: .complete))
        }
    }

    func start() {
        delay(timeout) { [weak self] in
            self?.delegate?.actionHandler(event: .dismiss(action: .timeout))
        }
    }

    func willDismiss(dismissAction: DismissAction) {
        self.badgeViewModel.collect()
    }
}

extension AnalyticsEvent {
    static func badgeCollected(_ badge: Badge) -> AnalyticsEvent {
        return AnalyticsEvent(name: "Badge Collected Button Pressed",
                              data: [.badgeID: badge.id,
                                     .badgeLevel: badge.level])
    }
}

extension AnalyticsEvent.Attribute {
    static var badgeID: Attribute = "Badge ID"
    static var badgeLevel: Attribute = "Level"
}
