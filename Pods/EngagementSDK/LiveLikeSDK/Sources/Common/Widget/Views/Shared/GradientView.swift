import UIKit

final class GradientView: UIView {

    enum Orientation {
        case horizontal
        case vertical
    }

    var livelike_startColor: UIColor = .clear {
        didSet {
            updateGradient()
        }
    }

    var livelike_endColor: UIColor = UIColor(white: 0, alpha: 0.65) {
        didSet {
            updateGradient()
        }
    }

    private var orientation: Orientation = .vertical
    private var gradientLayer: CAGradientLayer?

    init(orientation: Orientation = .vertical) {
        self.orientation = orientation
        super.init(frame: .zero)
        gradientLayer = layer as? CAGradientLayer
        configure()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer = layer as? CAGradientLayer
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gradientLayer = layer as? CAGradientLayer
        configure()
    }

    private func configure() {
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        updateOrientation()
    }

    override class var layerClass: Swift.AnyClass {
        return CAGradientLayer.self
    }

    var startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0) {
        didSet {
            updateGradient()
        }
    }

    var endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0) {
        didSet {
            updateGradient()
        }
    }

    override var livelike_cornerRadius: CGFloat {
        didSet {
            gradientLayer?.cornerRadius = livelike_cornerRadius
        }
    }

    private func updateGradient() {
        gradientLayer?.colors = [
            livelike_startColor.cgColor,
            livelike_endColor.cgColor
        ]
        gradientLayer?.startPoint = startPoint
        gradientLayer?.endPoint = endPoint
    }

    private func updateOrientation() {
        switch orientation {
        case .vertical:
            startPoint = CGPoint(x: 0.5, y: 0.0)
            endPoint = CGPoint(x: 0.5, y: 1.0)
        case .horizontal:
            startPoint = CGPoint(x: 0.0, y: 0.5)
            endPoint = CGPoint(x: 1.0, y: 0.5)
        }
    }
}
