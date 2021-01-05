//
//  ThemeableView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 6/29/20.
//

import UIKit

class ThemeableView: UIView {

    func applyContainerProperties(_ container: Theme.Container) {
        borderWidth = container.borderWidth
        borderColor = container.borderColor
        cornerRadii = container.cornerRadii
        background = container.background
    }

    var borderWidth: CGFloat = 0 {
        didSet {
            addOrUpdateBorderLayer(color: borderColor, width: borderWidth)
        }
    }

    var borderColor: UIColor = .clear {
        didSet {
            addOrUpdateBorderLayer(color: borderColor, width: borderWidth)
        }
    }

    var cornerRadii: Theme.CornerRadii = .zero {
        didSet {
            roundCorners(cornerRadii: cornerRadii)
        }
    }

    var background: Theme.Background? = .fill(color: .clear) {
        didSet {
            guard let background = background else { return }
            switch background {
            case .fill(let color):
                gradientBackgroundLayer.isHidden = true
                backgroundColor = color
            case .gradient(let gradient):
                gradientBackgroundLayer.isHidden = false
                gradientBackgroundLayer.colors = gradient.colors.map { $0.cgColor }
            }
        }
    }

    private var borderPath: UIBezierPath!
    private var borderLayer: CAShapeLayer?
    private var gradientBackgroundLayer: CAGradientLayer = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        borderPath = UIBezierPath(shouldRoundRect: bounds, cornerRadii: cornerRadii)
        updateBorderPath(borderPath: borderPath)
        backgroundColor = .clear
        clipsToBounds = true
        gradientBackgroundLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientBackgroundLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientBackgroundLayer.frame = bounds
        layer.insertSublayer(gradientBackgroundLayer, at: 0)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderPath = UIBezierPath(shouldRoundRect: bounds, cornerRadii: cornerRadii)
        updateBorderPath(borderPath: borderPath)
        gradientBackgroundLayer.frame = bounds
        borderLayer?.path = borderPath.cgPath
        borderLayer?.frame = bounds
    }

    private func addOrUpdateBorderLayer(color: UIColor, width: CGFloat) {
        if borderLayer == nil {
            let borderLayer = UIView.borderLayer(
                path: borderPath.cgPath,
                frame: bounds,
                borderColor: color,
                borderWidth: width
            )
            layer.addSublayer(borderLayer)
            self.borderLayer = borderLayer
        }

        borderLayer?.strokeColor = color.cgColor
        borderLayer?.lineWidth = width * 2
        borderLayer?.path = borderPath.cgPath
    }

    private func updateBorderPath(borderPath: UIBezierPath) {
        let shape = CAShapeLayer()
        shape.path = borderPath.cgPath
        layer.mask = shape
    }
}
