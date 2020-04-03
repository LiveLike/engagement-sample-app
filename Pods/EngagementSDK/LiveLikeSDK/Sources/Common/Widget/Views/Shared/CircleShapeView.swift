//
//  CircleShapeView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/25/19.
//

import UIKit

class CircleShapeView: UIView {
    private lazy var circleLayer: CAShapeLayer = {
        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = UIColor(white: 1, alpha: 0.4).cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = 2
        return circleLayer
    }()

    init() {
        super.init(frame: .zero)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        layer.addSublayer(circleLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = bounds.height / 2
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.height, height: bounds.height), cornerRadius: radius).cgPath
        circleLayer.frame = CGRect(x: bounds.midX - radius, y: bounds.midY - radius, width: bounds.height, height: bounds.height)
    }
}

// MARK: Properties

extension CircleShapeView {
    var fillColor: CGColor? {
        get { return circleLayer.fillColor }
        set { circleLayer.fillColor = newValue }
    }

    var strokeColor: CGColor? {
        get { return circleLayer.strokeColor }
        set { circleLayer.strokeColor = newValue }
    }
}

// MARK: Animations

extension CircleShapeView {
    func repeatingPulse(rate: TimeInterval, sizeMultiplier: CGFloat) {
        UIView.animate(withDuration: rate,
                       delay: 0.0,
                       options: [.repeat, .autoreverse],
                       animations: {
                           self.transform = self.transform.scaledBy(x: sizeMultiplier, y: sizeMultiplier)
        }, completion: nil)
    }

    func pulse(duration: TimeInterval, sizeMultiplier: CGFloat) {
        layer.removeAllAnimations()
        transform = .identity
        UIView.animate(withDuration: duration,
                       delay: 0.0,
                       options: [.curveEaseOut],
                       animations: {
                           self.alpha = 1
                           self.transform = self.transform.scaledBy(x: sizeMultiplier, y: sizeMultiplier)
                       }, completion: { finished in
                           if finished {
                               self.alpha = 0
                               self.transform = .identity
                           }

        })
    }
}
