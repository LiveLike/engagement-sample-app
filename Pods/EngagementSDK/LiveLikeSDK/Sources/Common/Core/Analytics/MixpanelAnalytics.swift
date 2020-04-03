//
//  MixpanelAnalytics.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/13/19.
//

import Mixpanel
enum MixpanelPropertyType: String {
    case peopleProperty = "People Property"
    case superProperty = "Super Property"
}

class MixpanelAnalytics: EventRecorder {
    let mixpanel: MixpanelInstance

    init(token: String) {
        mixpanel = Mixpanel.initialize(token: token)
        #if DEBUG
            mixpanel.loggingEnabled = true
        #endif
    }

    func record(_ event: AnalyticsEvent) {
        
        // Filtering out chat pause and widet pause calls for Mixpanel only
        // https://livelike.atlassian.net/browse/IOSSDK-911
        if event.name == .chatPauseStatusChanged || event.name == .widgetPauseStatusChanged {
            return
        }
        
        let metadata = event.metadata.reduce(into: [String: MixpanelType]()) { result, pair in
            guard let mixpanelValue = pair.value as? MixpanelType else {
                assertionFailure("Invalid value attempted to be sent to Mixpanel")
                return
            }
            result[pair.key.stringValue] = mixpanelValue
        }
        
        logMixPanel(event: event.name.stringValue, properties: metadata)
        mixpanel.track(event: event.name.stringValue, properties: metadata)
    }

    func logMixPanel(properties: [String: MixpanelType], type: MixpanelPropertyType) {
        properties.forEach { log.info("\(type.rawValue): \($0.key) = \($0.value)") }
    }
    
    func logMixPanel(event: String, properties: [String: MixpanelType]) {
        log.info("\(event): \(properties)")
    }
}

extension MixpanelAnalytics: SuperPropertyCache {
    func getProperty(name: SuperProperty.Name) -> Any? {
        let superProps = mixpanel.currentSuperProperties()
        return superProps[name.stringValue]
    }
}

extension MixpanelAnalytics: SuperPropertyRecorder {
    func register(_ properties: [SuperProperty]) {
        let propertyDict = properties.reduce(into: [String: Any]()) { $0[$1.name.stringValue] = $1.value }
        guard let superProperties = propertyDict as? [String: MixpanelType] else {
            assertionFailure("\(propertyDict)")
            return
        }
        logMixPanel(properties: superProperties, type: .superProperty)
        mixpanel.registerSuperProperties(superProperties)
    }

    func registerOnce(_ properties: [SuperProperty]) {
        let propertyDict = properties.reduce(into: [String: Any]()) { $0[$1.name.stringValue] = $1.value }
        guard let superProperties = propertyDict as? [String: MixpanelType] else {
            assertionFailure("\(propertyDict)")
            return
        }
        logMixPanel(properties: superProperties, type: .superProperty)
        mixpanel.registerSuperPropertiesOnce(superProperties)
    }

    func register(fromStringDict stringDict: [String: String]) {
        mixpanel.registerSuperProperties(stringDict)
    }
}

extension MixpanelAnalytics: PeoplePropertyRecorder {
    func record(_ properties: [PeopleProperty]) {
        let propertyDict = properties.reduce(into: [String: Any]()) { $0[$1.name] = $1.value }
        guard let peopleProperties = propertyDict as? [String: MixpanelType] else {
            assertionFailure("\(propertyDict)")
            return
        }
        logMixPanel(properties: peopleProperties, type: .peopleProperty)
        mixpanel.people.set(properties: peopleProperties)
    }

    func recordOnce(_ properties: [PeopleProperty]) {
        let propertyDict = properties.reduce(into: [String: Any]()) { $0[$1.name] = $1.value }
        guard let peopleProperties = propertyDict as? [String: MixpanelType] else {
            assertionFailure("\(propertyDict)")
            return
        }
        logMixPanel(properties: peopleProperties, type: .peopleProperty)
        mixpanel.people.setOnce(properties: peopleProperties)
    }

    func record(fromStringDict stringDict: [String: String]) {
        mixpanel.people.set(properties: stringDict)
    }

    func increment(_ property: PeopleProperty, by amount: Double = 1) {
        mixpanel.people.increment(property: property.name, by: amount)
    }
}

extension MixpanelAnalytics: IdentityRecorder {
    func identify(id: String) {
        mixpanel.identify(distinctId: id)
    }

    func alias(alias: String) {
        mixpanel.createAlias(alias, distinctId: mixpanel.distinctId)
        // Mixpanel recommends calling identify after alias https://developer.mixpanel.com/docs/swift#section-managing-user-identity
        mixpanel.identify(distinctId: mixpanel.distinctId)
    }
}
