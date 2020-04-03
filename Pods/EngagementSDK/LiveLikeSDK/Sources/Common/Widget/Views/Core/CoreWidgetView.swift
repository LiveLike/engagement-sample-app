//
//  WidgetView.swift
//  LiveLikeSDK
//
//  Created by Heinrich Dahms on 2019-01-29.
//

import UIKit

// Should maybe just be called WidgetView
class CoreWidgetView: UIView {
    // MARK: Internal Properties

    var coreWidgetYConstraint: NSLayoutConstraint?
    var coreWidgetXConstraint: NSLayoutConstraint?

    var headerView: UIView? {
        didSet {
            if headerView == nil {
                headerView = UIView(frame: .zero)
            }
            viewDidChange(from: oldValue, to: headerView, position: 0)
        }
    }

    var contentView: UIView? {
        didSet {
            if contentView == nil {
                contentView = UIView(frame: .zero)
            }
            viewDidChange(from: oldValue, to: contentView, position: 1)
        }
    }

    var footerView: UIView? {
        didSet {
            if footerView == nil {
                footerView = UIView(frame: .zero)
            }
            viewDidChange(from: oldValue, to: footerView, position: 2)
        }
    }

    // MARK: Internal Properties

    let stackView: UIStackView = UIStackView()
    let baseView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false
        setupBaseView()
        setupStackView()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let newSuperview = superview, coreWidgetYConstraint == nil, coreWidgetXConstraint == nil {
            coreWidgetXConstraint = centerXAnchor.constraint(equalTo: newSuperview.centerXAnchor)
            coreWidgetYConstraint = topAnchor.constraint(equalTo: newSuperview.topAnchor)

            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalTo: newSuperview.widthAnchor, constant: -32),
                coreWidgetXConstraint!,
                coreWidgetYConstraint!
            ])
        }
    }

    private func setupBaseView() {
        addSubview(baseView)
        baseView.constraintsFill(to: self)
    }

    private func setupStackView() {
        baseView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 0

        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func viewDidChange(from oldView: UIView?, to newView: UIView?, position: Int) {
        guard newView !== oldView else {
            return
        }

        oldView?.removeFromSuperview()

        guard let newView = newView else {
            return
        }

        newView.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertArrangedSubview(newView, at: position)

        let constraints = [
            newView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
