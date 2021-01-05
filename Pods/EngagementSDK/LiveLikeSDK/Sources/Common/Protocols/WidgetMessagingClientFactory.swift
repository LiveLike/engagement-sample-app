//
//  WidgetMessagingProtocol.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-01-29.
//

import UIKit

protocol WidgetMessagingClientFactory {
    func widgetMessagingClient(subcribeKey: String, origin: String?, userID: String) -> WidgetClient
}
