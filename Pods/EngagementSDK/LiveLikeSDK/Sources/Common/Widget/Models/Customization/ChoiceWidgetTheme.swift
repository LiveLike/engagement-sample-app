//
//  ChoiceWidgetTheme.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/19/20.
//

import UIKit

//swiftlint:disable nesting
extension Theme {
    public typealias BorderWidth = CGFloat
    public typealias BorderColor = UIColor

    public struct CornerRadii {
        public init(
            topLeft: CornerRadius,
            topRight: CornerRadius,
            bottomLeft: CornerRadius,
            bottomRight: CornerRadius
        ) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomLeft = bottomLeft
            self.bottomRight = bottomRight
        }

        public init(all: CornerRadius) {
            self.init(topLeft: all, topRight: all, bottomLeft: all, bottomRight: all)
        }

        public typealias CornerRadius = CGFloat

        public var topLeft: CornerRadius
        public var topRight: CornerRadius
        public var bottomLeft: CornerRadius
        public var bottomRight: CornerRadius

        public static var zero = CornerRadii(all: 0)
    }
    public typealias TextColor = UIColor
    public typealias TextFont = UIFont

    public struct Text {
        public init(
            color: Theme.TextColor,
            font: Theme.TextFont
        ) {
            self.color = color
            self.font = font
        }

        public var color: TextColor
        public var font: TextFont
    }

    public struct Container {
        public init(
            background: Theme.Background,
            borderColor: Theme.BorderColor,
            borderWidth: Theme.BorderWidth,
            cornerRadii: Theme.CornerRadii
        ) {
            self.background = background
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.cornerRadii = cornerRadii
        }

        public var background: Background
        public var borderColor: BorderColor
        public var borderWidth: BorderWidth
        public var cornerRadii: CornerRadii
    }

    public struct ProgressBar {
        public init(
            background: Theme.Background,
            borderColor: Theme.BorderColor,
            borderWidth: Theme.BorderWidth,
            cornerRadii: Theme.CornerRadii
        ) {
            self.background = background
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.cornerRadii = cornerRadii
        }

        public var background: Background
        public var borderColor: BorderColor
        public var borderWidth: BorderWidth
        public var cornerRadii: CornerRadii
    }

    public struct ChoiceWidget {
        public init(
            main: Theme.Container,
            header: Theme.Container,
            body: Theme.Container,
            title: Theme.Text,
            correctOption: Theme.ChoiceWidget.Option? = nil,
            incorrectOption: Theme.ChoiceWidget.Option? = nil,
            selectedOption: Theme.ChoiceWidget.Option,
            unselectedOption: Theme.ChoiceWidget.Option
        ) {
            self.main = main
            self.header = header
            self.body = body
            self.title = title
            self.correctOption = correctOption
            self.incorrectOption = incorrectOption
            self.selectedOption = selectedOption
            self.unselectedOption = unselectedOption
        }

        public var main: Container
        public var header: Container
        public var body: Container
        public var title: Text

        public var correctOption: Option?
        public var incorrectOption: Option?
        public var selectedOption: Option
        public var unselectedOption: Option

        public struct Option {
            public init(
                container: Theme.Container,
                description: Theme.Text,
                percentage: Theme.Text,
                progressBar: Theme.ProgressBar
            ) {
                self.container = container
                self.description = description
                self.percentage = percentage
                self.progressBar = progressBar
            }

            public var container: Container
            public var description: Text
            public var percentage: Text
            public var progressBar: ProgressBar
        }
    }
}
