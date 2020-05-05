//
//  GamificationViewManager.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 8/2/19.
//

import UIKit

// Hook into WidgetViewController to show gamification ui at correct moment
class GamificationViewManager {
    private let rewards: Rewards
    private var currentWidgetRewardsView: RewardsView?
    private let storeWidgetProxy: StoreWidgetProxy
    private let theme = Theme()
    private let eventRecorder: EventRecorder

    private let tutorialCompleteUserDefaultKey = "EngagementSDK.gamificationTutorialCompleted"
    private var didCompleteTutorial: Bool {
        didSet {
            UserDefaults.standard.set(didCompleteTutorial, forKey: tutorialCompleteUserDefaultKey)
        }
    }

    init(storeWidgetProxy: StoreWidgetProxy,
         widgetRendererDelegator: WidgetRendererDelegator,
         widgetEventDelegator: WidgetEventsDelegator,
         rewards: Rewards,
         eventRecorder: EventRecorder) {
        self.storeWidgetProxy = storeWidgetProxy
        self.rewards = rewards
        self.eventRecorder = eventRecorder
        didCompleteTutorial = UserDefaults.standard.bool(forKey: tutorialCompleteUserDefaultKey)
        widgetRendererDelegator.subscribe(widgetRendererDelegate: self)
        widgetEventDelegator.subscribe(widgetEventsDelegate: self)
        rewards.addDelegate(self)
    }
}

extension GamificationViewManager: WidgetRendererDelegate {
    
    func widgetWillStopRendering(widget: WidgetViewModel) { }
    
    func widgetDidStopRendering(widget: WidgetViewModel, dismissAction: DismissAction) {
        currentWidgetRewardsView = nil
    }

    func widgetDidStartRendering(widget: WidgetController) {
        // inject gamification ui
        if let injectableView = widget as? ViewInjectable {
            let rewardsView: (RewardsView & UIView) = {
                let rewardsView = WidgetPointsAndBadgeProgress()
                rewardsView.translatesAutoresizingMaskIntoConstraints = false
                rewardsView.setTheme(self.theme)
                return rewardsView
            }()
            injectableView.injectView(rewardsView)
            currentWidgetRewardsView = rewardsView
        }

        // follow up widgets can try to display awards immediately
        if widget.kind == WidgetKind.imagePredictionFollowUp
            || widget.kind == WidgetKind.textPredictionFollowUp
        {
            rewards.getPointsReward(for: widget.id)
        }
    }
}

// hook into widget events
extension GamificationViewManager: WidgetEvents {
    func actionHandler(event: WidgetEvent) {}
    func widgetInteractionDidBegin(widget: WidgetViewModel) {}    
    func widgetInteractionDidComplete(properties: WidgetInteractedProperties) {
        rewards.getPointsReward(for: properties.widgetId)
    }
}

extension GamificationViewManager: RewardsDelegate {
    func rewards(didRecieveError error: Error) {
        log.error(error.localizedDescription)
    }

    func rewards(didReceiveAwards awards: Awards, awardsProfile: AwardsProfile, widgetID: String) {
        let awardsViewModel = AwardsViewModel.create(profileBeforeNewAwards: awardsProfile, newAwards: awards, rewards: rewards)

        // if earned 0 points, do not show anything
        guard awardsViewModel.newPointsEarned > 0.0 else { return }
        
        let packagedAwardsViewModel = ["awardsModel": awardsViewModel]

        if awardsViewModel.newBadgeEarned != nil {
            self.storeWidgetProxy.addToFrontOfQueue(event: .badgeCollect(awardsViewModel))
        }
        
        if !didCompleteTutorial {
            // Enqueue gamification ui tutorial
            self.storeWidgetProxy.addToFrontOfQueue(event: .pointsTutorial(awardsViewModel))
            self.didCompleteTutorial = true
        } else {
            currentWidgetRewardsView?.apply(viewModel: awardsViewModel, animated: true)
        }
        
        NotificationCenter.default.post(name: .didReceiveAwards, object: nil, userInfo: packagedAwardsViewModel)
    }

    func rewards(noAwardsForWidget widgetID: String) {}
}

extension Notification.Name {
    static let didReceiveAwards = NSNotification.Name("LiveLikeSDK.didReceiveAwards")
}
