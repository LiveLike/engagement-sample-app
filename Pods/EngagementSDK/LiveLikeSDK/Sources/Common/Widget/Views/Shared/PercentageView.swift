import UIKit

class ProgressBarAndLabelView: UIView {
    var progressLabel = ProgressLabel()
    var progressBar = ProgressBar()
    
    func setLabelTextColor(_ color: UIColor) {
        progressLabel.textColor = color
    }

    func setLabelFont(_ font: UIFont) {
        progressLabel.font = font
    }

    func setBarColors(startColor: UIColor, endColor: UIColor) {
        progressBar.setColors(startColor: startColor, endColor: endColor)
    }

    func setBarCornerRadius(_ cornerRadius: CGFloat) {
        progressBar.gradientView.livelike_cornerRadius = cornerRadius / 2
    }

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(progressBar)
        addSubview(progressLabel)
        configureStyle()
        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = false
        addSubview(progressBar)
        addSubview(progressLabel)
        configureStyle()
        configureLayout()
    }

    func setProgress(percent: CGFloat) {
        assert((0 ... 1).contains(percent), "Percent needs to be between 0 and 1")
        let progress = (0 ... 1).clamp(percent)
        progressLabel.setProgress(progress)
        progressBar.setProgress(progress)
    }

    func configureStyle() {
        progressLabel.textAlignment = .right
    }

    func configureLayout() {
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        progressBar.constraintsFill(to: self)
    }
}

class ProgressBar: UIView {

    var background: Theme.Background = .fill(color: .clear) {
        didSet {
            switch background {
            case .fill(let color):
                setColors(startColor: color, endColor: color)
            case .gradient(let gradient):
                guard
                    let startColor = gradient.colors[safe: 0],
                    let endColor = gradient.colors[safe: 1]
                else {
                    return
                }

                setColors(startColor: startColor, endColor: endColor)
            }
        }
    }

    private var progress: CGFloat = 0.0

    init() {
        super.init(frame: .zero)
        addSubview(gradientView)
        gradientView.constraintsFill(to: self)
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var gradientView: GradientView = {
        let gradientView = GradientView(orientation: .horizontal)
        gradientView.isUserInteractionEnabled = false
        return gradientView
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientFrame()
    }

    func setColors(startColor: UIColor, endColor: UIColor) {
        gradientView.livelike_startColor = startColor
        gradientView.livelike_endColor = endColor
    }
    
    func animateProgress(from: CGFloat, to: CGFloat, max: CGFloat, duration: TimeInterval = 0.3, delay: TimeInterval = 0) {
        progress = max != 0 ? from / max : 0
        UIView.performWithoutAnimation {
            updateGradientFrame()
        }
        progress = max != 0 ? to / max : 0
        UIView.animate(withDuration: duration, delay: delay, options: [], animations: {
            self.updateGradientFrame()
        })
    }
    
    func setProgress(from: CGFloat, to: CGFloat, max: CGFloat) {
        progress = max != 0 ? to / max : 0
        UIView.performWithoutAnimation {
            updateGradientFrame()
        }
    }

    func setProgress(_ percent: CGFloat, animationDuration: TimeInterval = 0.3, animationDelay: TimeInterval = 0) {
        progress = percent
        UIView.animate(withDuration: animationDuration, delay: animationDelay, options: [], animations: {
            self.updateGradientFrame()
        })
    }

    private func updateGradientFrame() {
        progress = (0 ... 1).clamp(progress)
        gradientView.frame = CGRect(x: 0, y: 0, width: bounds.width * progress, height: bounds.height)
    }
}

class ProgressLabel: UILabel {
    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.multiplier = 100
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()

    func setProgress(_ percent: CGFloat) {
        text = numberFormatter.string(for: percent)
    }
}
