//
//  OnPublishProxy.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/15/20.
//

import Foundation

class OnPublishProxy: WidgetProxy {
    
    private let onPublish: (WidgetProxyPublishData) -> Void
    
    init(_ onPublish: @escaping (WidgetProxyPublishData) -> Void) {
        self.onPublish = onPublish
    }
    
    func publish(event: WidgetProxyPublishData) {
        self.onPublish(event)
        self.downStreamProxyInput?.publish(event: event)
    }
    
    var downStreamProxyInput: WidgetProxyInput?
    
}
