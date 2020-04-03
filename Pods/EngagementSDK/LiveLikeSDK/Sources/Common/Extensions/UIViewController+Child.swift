//
//  UIViewController+Child.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-21.
//

import UIKit

extension UIViewController {
    /**
     Convenience function to insert a UIViewController into the specified view.

     Also takes care of inserting the subview, constraints (fills the entire given view) and notifies the view controller that is has moved to a new parent.

     - parameter viewController: View controller that needs to be inserted.
     - parameter view: View that given `viewController` is inserted into.
     */
    func addChild(viewController: UIViewController, into view: UIView) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)

        let constraints = [
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    /**
     Convenience function for removing all child view controllers from a given UIViewController.
     */
    func removeAllChildViewControllers() {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
    }
}
