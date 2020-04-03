//
//  UIView+Constraints.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-21.
//

import UIKit

extension UIView {
    func constraintsFill(to parentView: UIView, offset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            parentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset),
            parentView.topAnchor.constraint(equalTo: topAnchor, constant: -offset),
            parentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: offset),
            parentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -offset)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func fillConstraints(to view: UIView, offset: CGFloat = 0) -> [NSLayoutConstraint] {
        return [
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset),
            view.topAnchor.constraint(equalTo: topAnchor, constant: -offset),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: offset),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -offset)
        ]
    }
}

extension UIView {
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.topAnchor
        }
        return topAnchor
    }

    var safeLeftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.leftAnchor
        }
        return leftAnchor
    }

    var safeRightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.rightAnchor
        }
        return rightAnchor
    }

    var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.bottomAnchor
        }
        return bottomAnchor
    }

    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.trailingAnchor
        }
        return trailingAnchor
    }

    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.leadingAnchor
        }
        return leadingAnchor
    }
}

extension UIView {
    func findConstraint(layoutAttribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        if let constraints = superview?.constraints {
            for constraint in constraints where itemMatch(constraint: constraint, layoutAttribute: layoutAttribute) {
                return constraint
            }
        }
        return nil
    }

    func itemMatch(constraint: NSLayoutConstraint, layoutAttribute: NSLayoutConstraint.Attribute) -> Bool {
        if let firstItem = constraint.firstItem as? UIView, let secondItem = constraint.secondItem as? UIView {
            let firstItemMatch = firstItem == self && constraint.firstAttribute == layoutAttribute
            let secondItemMatch = secondItem == self && constraint.secondAttribute == layoutAttribute
            return firstItemMatch || secondItemMatch
        }
        return false
    }
}
