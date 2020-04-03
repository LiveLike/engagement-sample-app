//
//  HorizontalScrollView.swift
//  LiveLikeSDK
//
//  Created by jelzon on 2/25/19.
//

import UIKit

class HorizontalScrollingStackView: UIScrollView {
    var spacing: CGFloat {
        didSet {
            stackView.spacing = spacing
        }
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        return stackView
    }()

    init() {
        spacing = 10 // default
        super.init(frame: .zero)

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        spacing = 10 // default
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        showsHorizontalScrollIndicator = false
        addSubview(stackView)
        delegate = self

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.heightAnchor.constraint(equalTo: heightAnchor)

        ])
    }

    func addArrangedSubview(_ view: UIView) {
        stackView.addArrangedSubview(view)
    }
}

extension HorizontalScrollingStackView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIApplication.shared.sendAction(#selector(WidgetViewController.scrollViewDidChange(_:)), to: nil, from: scrollView, for: nil)
    }
}

extension UIScrollView {
    func scrollToView(view: UIView, animated: Bool) {
        if let origin = view.superview {
            let childStartPoint = origin.convert(view.frame.origin, to: self)
            scrollRectToVisible(CGRect(x: childStartPoint.x, y: 0, width: frame.width, height: 1), animated: animated)
        }
    }
}
