//
//  Analytics.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/13/19.
//

import Foundation

class Analytics: EventRecorder {
    weak var delegate: EngagementAnalyticsDelegate?

    private var widgetPropertyRecorder: WidgetPropertyRecorder?

    private let applicationConfigVendor: ApplicationConfigVendor
    private lazy var whenMixpanel: Promise<MixpanelAnalytics> =
        firstly {
            applicationConfigVendor.whenApplicationConfig
        }.then { (appConfig) -> Promise<MixpanelAnalytics> in
            self.initializeMixpanel(appConfig: appConfig)
        }

    init(applicationConfigVendor: ApplicationConfigVendor) {
        self.applicationConfigVendor = applicationConfigVendor
    }

    func record(_ event: AnalyticsEvent) {
        log.info("\(event.name)\n\(event.metadata as AnyObject)")

        widgetPropertyRecorder?.handleEvent(event: event)

        whenMixpanel.then { mixpanel in
            mixpanel.record(event)
        }.catch {
            log.error($0.localizedDescription)
        }

        if let delegate = delegate, event.isClientReadable {
            // Repeat event to client
            let data = event.metadata.reduce(into: [String: Any]()) { result, pair in
                result[pair.key.stringValue] = pair.value
            }
            delegate.engagementAnalyticsEvent(name: event.name.stringValue,
                                              withData: data)
        }
    }

    private func initializeClientDetailSuperProperties(appConfig: ApplicationConfiguration) {
        register({
            var superProperties: [SuperProperty] = [
                .league(leagueName: ""),
                .programId(id: ""),
                .programName(name: ""),
                .sport(sportName: ""),
                .sdkVersion(version: EngagementSDK.version)
            ]

            if let officialAppName = Bundle.main.displayName {
                superProperties.append(.officialAppName(officialAppName: officialAppName))
            }

            return superProperties
        }())

        register(fromStringDict: appConfig.analyticsProperties)
    }

    private func initializePeopleProperties(with appConfig: ApplicationConfiguration) {
        record(fromStringDict: appConfig.analyticsProperties)
    }

    private func initializeMixpanel(appConfig: ApplicationConfiguration) -> Promise<MixpanelAnalytics> {
        return Promise(work: { complete, error in
            if let mixpanelToken = appConfig.mixpanelToken {
                let mixpanelAnalytics = MixpanelAnalytics(token: mixpanelToken)
                self.widgetPropertyRecorder = WidgetPropertyRecorder(superPropertyRecorder: self, peoplePropertyRecorder: self)
                self.initializeClientDetailSuperProperties(appConfig: appConfig)
                self.initializePeopleProperties(with: appConfig)
                self.incrementAppOpenCountProperty(superPropertyCache: mixpanelAnalytics)
                complete(mixpanelAnalytics)
            } else {
                error(NilError())
                log.error("Will not initialize Mixpanel because no token available.")
            }
        })
    }

    // Increments the appOpenCount from the cache and then registers the new value
    // If appOpenCount doesn't exist in cache then initialize it to 1 to indicate the first use
    // https://help.mixpanel.com/hc/en-us/articles/115004601563-Mobile-Incremental-Super-Properties
    func incrementAppOpenCountProperty(superPropertyCache: SuperPropertyCache) {
        guard let appOpenCount = superPropertyCache.getProperty(name: SuperProperty.Name.appOpenCount) as? Int else {
            register([.appOpenCount(count: 1)])
            return
        }

        register([.appOpenCount(count: appOpenCount + 1)])
    }
}

extension Analytics: SuperPropertyRecorder {
    func register(fromStringDict stringDict: [String: String]) {
        whenMixpanel.then { mixpanel in
            stringDict.forEach { log.info("Super Property: \($0.key) = \($0.value)") }
            mixpanel.register(fromStringDict: stringDict)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func register(_ properties: [SuperProperty]) {
        whenMixpanel.then { mixpanel in
            mixpanel.register(properties)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func registerOnce(_ properties: [SuperProperty]) {
        whenMixpanel.then { mixpanel in
            mixpanel.registerOnce(properties)
        }.catch {
            log.error($0.localizedDescription)
        }
    }
}

extension Analytics: PeoplePropertyRecorder {
    func record(fromStringDict stringDict: [String: String]) {
        whenMixpanel.then { mixpanel in
            stringDict.forEach { log.info("People Property: \($0.key) = \($0.value)") }
            mixpanel.record(fromStringDict: stringDict)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func increment(_ property: PeopleProperty, by amount: Double = 1) {
        whenMixpanel.then { mixpanel in
            mixpanel.increment(property, by: amount)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func record(_ properties: [PeopleProperty]) {
        whenMixpanel.then { mixpanel in
            mixpanel.record(properties)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func recordOnce(_ properties: [PeopleProperty]) {
        whenMixpanel.then { mixpanel in
            mixpanel.recordOnce(properties)
        }.catch {
            log.error($0.localizedDescription)
        }
    }
}

extension Analytics: IdentityRecorder {
    func identify(id: String) {
        whenMixpanel.then { mixpanel in
            mixpanel.identify(id: id)
        }.catch {
            log.error($0.localizedDescription)
        }
    }

    func alias(alias: String) {
        whenMixpanel.then { mixpanel in
            mixpanel.alias(alias: alias)
        }.catch {
            log.error($0.localizedDescription)
        }
    }
}
