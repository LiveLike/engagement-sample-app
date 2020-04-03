//
//  MultiGradientView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/20/19.
//

import UIKit

class MultiGradientView: UIView {
    var colors: [CGColor]? {
        didSet {
            gradientLayer.colors = colors
        }
    }

    var startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0) {
        didSet {
            gradientLayer.startPoint = startPoint
        }
    }

    var endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0) {
        didSet {
            gradientLayer.endPoint = endPoint
        }
    }

    var locations: [NSNumber]? {
        didSet {
            gradientLayer.locations = locations
        }
    }

    override var livelike_cornerRadius: CGFloat {
        didSet {
            gradientLayer.cornerRadius = livelike_cornerRadius
        }
    }

    private let gradientLayer = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        configure()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradientLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
