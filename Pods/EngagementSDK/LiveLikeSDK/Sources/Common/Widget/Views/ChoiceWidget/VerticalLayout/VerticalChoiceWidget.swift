//
//  VerticalChoiceWidget.swift
//  EngagementSDK
//
//  Created by jelzon on 2/15/19.
//

import Lottie
import UIKit

/// A vertical layout for choice widgets
class VerticalChoiceWidget: ChoiceWidgetView {
    let coreWidgetView = CoreWidgetView()
    lazy var titleView = WidgetTitleView()

    var contentBackgroundColor: UIColor? {
        get { return stackViewContainer.backgroundColor }
        set { stackViewContainer.backgroundColor = newValue }
    }

    private var stackViewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var lottieView: AnimationView = AnimationView()

    var stackView: UIStackView = {
        let stackView = UIStackView.verticalStackView()
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        addSubview(coreWidgetView)
        coreWidgetView.constraintsFill(to: self)
        
        stackViewContainer.addSubview(stackView)
        stackView.constraintsFill(to: stackViewContainer)

        coreWidgetView.headerView = titleView
        coreWidgetView.contentView = stackViewContainer
    }

    func populateStackView(options: [ChoiceWidgetOptionButton]) {
        for option in options {
            stackView.addArrangedSubview(option)
            let constraints = [
                option.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                option.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
        }
    }

    func playOverlayAnimation(animationFilepath: String, completion:(() -> Void)?) {
        lottieView = AnimationView(filePath: animationFilepath)
        lottieView.isUserInteractionEnabled = false
        lottieView.contentMode = .scaleAspectFit
        lottieView.sizeToFit()
        lottieView.frame = CGRect(x: 0, y: 0, width: coreWidgetView.bounds.width, height: coreWidgetView.bounds.height)
        coreWidgetView.clipsToBounds = false
        coreWidgetView.addSubview(lottieView)

        lottieView.play { finished in
            if finished {
                UIView.animate(withDuration: 0.33, animations: {
                    self.lottieView.alpha = 0.0
                }, completion: { _ in
                    self.lottieView.removeFromSuperview()
                    completion?()
                })
            }
        }
    }
    
    func stopOverlayAnimation() {
        lottieView.stop()
    }
}
