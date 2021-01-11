//
//  AlertWidgetTheme.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-03-21.
//

import UIKit

extension Theme {
    /// Customizable properties of the Alert Widget
    public struct AlertWidget {
        public init(
            main: Theme.Container,
            header: Theme.Container,
            title: Theme.Text,
            body: Theme.Container,
            description: Theme.Text,
            footer: Theme.Container,
            link: Theme.Text
        ) {
            self.main = main
            self.header = header
            self.title = title
            self.body = body
            self.description = description
            self.footer = footer
            self.link = link
        }

        public var main: Container

        public var header: Container
        public var title: Text

        public var body: Container
        public var description: Text

        public var footer: Container
        public var link: Text
    }
}
