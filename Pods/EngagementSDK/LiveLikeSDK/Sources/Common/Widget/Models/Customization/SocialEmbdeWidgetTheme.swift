//
//  SocialEmbdeWidgetTheme.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 2/12/21.
//

import UIKit

extension Theme {
    /// Customizable properties of the Social Embed Widget
    public struct SocialEmbedWidget {
        public init(
            main: Theme.Container,
            header: Theme.Container,
            title: Theme.Text,
            body: Theme.Container
        ) {
            self.main = main
            self.header = header
            self.title = title
            self.body = body
        }

        public var main: Container

        public var header: Container
        public var title: Text

        public var body: Container
    }
}
