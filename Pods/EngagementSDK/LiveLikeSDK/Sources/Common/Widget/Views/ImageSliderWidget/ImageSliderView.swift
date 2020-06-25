//
//  ImageSliderView.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 5/13/19.
//

import Lottie
import UIKit

class ImageSliderView: UIView {
    private let minimumSize: Float = 36
    private let maximumSize: Float = 54
    private var thumbImages = [UIImage]()
    private let thumbImageUrls: [URL]
    private let initialSliderValue: Float
    private let timerAnimationFilepath: String

    let coreWidgetView = CoreWidgetView()

    var titleView: UIView = {
        let titleView = UIView()
        titleView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        return titleView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    var bodyView: UIView = {
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        return background
    }()

    lazy var timerView: AnimationView = {
        let lottieView = AnimationView(filePath: self.timerAnimationFilepath)
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.contentMode = .scaleAspectFit
        return lottieView
    }()

    var customSliderTrack: GradientView = {
        let gradient = GradientView(orientation: .horizontal)
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.isUserInteractionEnabled = false
        gradient.livelike_cornerRadius = 9
        return gradient
    }()

    var closeButton: UIButton = {
        let image = UIImage(named: "widget_close", in: Bundle(for: WidgetTitleView.self), compatibleWith: nil)
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(image, for: .normal)
        button.isHidden = true
        return button
    }()

    private var titleLeadingConstraint: NSLayoutConstraint!
    private var titleTrailingConstraint: NSLayoutConstraint!
    private var titleTopConstraint: NSLayoutConstraint!
    private var titleBottomConstraint: NSLayoutConstraint!

    var titleMargins: UIEdgeInsets = .zero {
        didSet {
            titleLeadingConstraint.constant = titleMargins.left
            titleTrailingConstraint.constant = titleMargins.right
            titleTopConstraint.constant = titleMargins.top
            titleBottomConstraint.constant = titleMargins.bottom
        }
    }

    var resultsHotColor: UIColor = .red {
        didSet {
            resultsSliderTrack.colors = [resultsColdColor.cgColor, resultsHotColor.cgColor, resultsColdColor.cgColor]
        }
    }

    var resultsColdColor: UIColor = .blue {
        didSet {
            resultsSliderTrack.colors = [resultsColdColor.cgColor, resultsHotColor.cgColor, resultsColdColor.cgColor]
        }
    }

    private var resultsTrackZeroWidthConstraint: NSLayoutConstraint!
    private var resultsTrackFinalWidthConstraint: NSLayoutConstraint!

    var resultsSliderTrack: MultiGradientView = {
        let view = MultiGradientView()
        view.startPoint = CGPoint(x: 0, y: 0.5)
        view.endPoint = CGPoint(x: 1, y: 0.5)
        view.livelike_cornerRadius = 9
        view.isHidden = true
        return view
    }()

    private var averageAnimationLeadingConstraint: NSLayoutConstraint?

    var avgIndicatorView: AnimationView = {
        let lottie = AnimationView(name: "image-slider-avg", bundle: Bundle(for: ImageSliderView.self))
        lottie.translatesAutoresizingMaskIntoConstraints = false
        lottie.contentMode = .scaleAspectFit
        return lottie
    }()

    var sliderView: UISlider = {
        let slider = CustomSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.maximumTrackTintColor = .white
        slider.minimumTrackTintColor = .clear
        slider.minimumValue = 0
        slider.maximumValue = 1
        return slider
    }()

    var averageVote: Float = 0.5 {
        didSet {
            resultsSliderTrack.locations = [averageVote - 0.3, averageVote, averageVote + 0.3] as [NSNumber]
            refreshAverageAnimationLeadingConstraint()
        }
    }

    // MARK: - Init

    init(thumbImageUrls: [URL], initialSliderValue: Float, timerAnimationFilepath: String) {
        self.thumbImageUrls = thumbImageUrls
        self.initialSliderValue = initialSliderValue
        self.timerAnimationFilepath = timerAnimationFilepath
        super.init(frame: CGRect.zero)
        self.configureLayout()
        Cache.shared.downloadAndCacheImages(urls: thumbImageUrls) { [weak self] in
            guard let self = self else { return }
            thumbImageUrls.forEach { imageUrl in
                Cache.shared.get(key: imageUrl.absoluteString) { (data: Data?) in
                    guard let data = data else { return }
                    guard let image = UIImage.decode(data) else { return }
                    self.thumbImages.append(image)
                }
            }
            
            self.configureSlider()
            
        }
    }

    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }

    // MARK: Public methods

    func showResultsTrack() {
        resultsSliderTrack.isHidden = false
        sliderView.minimumTrackTintColor = .clear
        sliderView.maximumTrackTintColor = .clear

        resultsTrackZeroWidthConstraint.priority = .defaultLow
        resultsTrackFinalWidthConstraint.priority = .defaultHigh
    }

    // MARK: Private methods

    private func refreshAverageAnimationLeadingConstraint() {
        averageAnimationLeadingConstraint?.isActive = false

        let averageXPosition = CGFloat(averageVote) * customSliderTrack.bounds.width
        averageAnimationLeadingConstraint = avgIndicatorView.centerXAnchor.constraint(equalTo: customSliderTrack.leadingAnchor,
                                                                                      constant: averageXPosition)
        averageAnimationLeadingConstraint!.isActive = true
    }

    @objc private func sliderValueChanged() {
        let newThumbSize = getThumbSize()
        let newThumbImage = getThumbImage().scaleToSize(newSize: newThumbSize)
        sliderView.setThumbImage(newThumbImage, for: .normal)
    }

    private func configureLayout() {
        coreWidgetView.headerView = titleView
        coreWidgetView.contentView = bodyView
        addSubview(coreWidgetView)
        coreWidgetView.constraintsFill(to: self)

        titleView.addSubview(timerView)
        titleView.addSubview(titleLabel)
        titleView.addSubview(closeButton)

        bodyView.addSubview(customSliderTrack)
        bodyView.addSubview(resultsSliderTrack)
        bodyView.addSubview(sliderView)
        bodyView.addSubview(avgIndicatorView)
        
        resultsTrackZeroWidthConstraint = resultsSliderTrack.widthAnchor.constraint(equalToConstant: 0)
        resultsTrackFinalWidthConstraint = resultsSliderTrack.widthAnchor.constraint(equalTo: customSliderTrack.widthAnchor)

        titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor)
        titleTrailingConstraint = titleLabel.trailingAnchor.constraint(equalTo: timerView.leadingAnchor)
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: titleView.topAnchor)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor)

        resultsTrackZeroWidthConstraint.priority = .defaultHigh
        resultsTrackFinalWidthConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            titleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 35),

            titleLeadingConstraint,
            titleTrailingConstraint,
            titleTopConstraint,
            titleBottomConstraint,

            timerView.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant: -10),
            timerView.heightAnchor.constraint(equalToConstant: 18),
            timerView.widthAnchor.constraint(equalToConstant: 18),
            timerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),

            bodyView.heightAnchor.constraint(equalToConstant: 60),

            customSliderTrack.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor),
            customSliderTrack.centerXAnchor.constraint(equalTo: bodyView.centerXAnchor),
            customSliderTrack.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 40),
            customSliderTrack.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor, constant: -40),
            customSliderTrack.heightAnchor.constraint(equalToConstant: 18),

            resultsSliderTrack.centerYAnchor.constraint(equalTo: customSliderTrack.centerYAnchor),
            resultsSliderTrack.centerXAnchor.constraint(equalTo: customSliderTrack.centerXAnchor),
            resultsSliderTrack.heightAnchor.constraint(equalToConstant: 18),
            resultsTrackZeroWidthConstraint,
            resultsTrackFinalWidthConstraint,

            avgIndicatorView.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor),
            avgIndicatorView.widthAnchor.constraint(equalToConstant: 20),
            avgIndicatorView.heightAnchor.constraint(equalToConstant: 60),

            sliderView.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor),
            sliderView.centerXAnchor.constraint(equalTo: bodyView.centerXAnchor),
            sliderView.heightAnchor.constraint(equalToConstant: 18),
            sliderView.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 40),
            sliderView.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor, constant: -40)
        ])
        
        refreshAverageAnimationLeadingConstraint()

        closeButton.constraintsFill(to: timerView)
    }

    private func configureSlider() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
            self.sliderView.setValue(self.initialSliderValue, animated: true)
            let newThumbSize = self.getThumbSize()
            let newThumbImage = self.getThumbImage().scaleToSize(newSize: newThumbSize)
            self.sliderView.setThumbImage(newThumbImage, for: .normal)
        }
    }

    private func getThumbSize() -> CGSize {
        if thumbImages.count <= 2 {
            let length = CGFloat(Math.lerp(start: minimumSize, end: maximumSize, t: sliderView.value))
            return CGSize(width: length, height: length)
        } else {
            let length = CGFloat(vCurve(minimum: minimumSize, maximum: maximumSize, t: sliderView.value, tMax: 1))
            return CGSize(width: length, height: length)
        }
    }

    private func getThumbImage() -> UIImage {
        if thumbImages.count == 1 {
            return thumbImages[0]
        } else {
            let imageIndex: Int = Int(round(sliderView.value * Float(thumbImages.count - 1)))
            return thumbImages[imageIndex]
        }
    }

    private func vCurve(minimum: Float, maximum: Float, t: Float, tMax: Float) -> Float {
        if t < tMax / 2 {
            return Math.lerp(start: maximum, end: minimum, t: t)
        } else {
            return Math.lerp(start: minimum, end: maximum, t: t)
        }
    }
}

class CustomSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = 18
        newBounds.origin.y = 0
        return newBounds
    }
}

extension UIImage {
    /// Maintains original image's aspect ratio
    func scaleToSize(newSize: CGSize) -> UIImage {
        let oldWidth = size.width
        let oldHeight = size.height

        // Scale to max width or max height
        let scaleFactor = (oldWidth > oldHeight) ? newSize.width / oldWidth : newSize.height / oldHeight

        let newHeight = oldHeight * scaleFactor
        let newWidth = oldWidth * scaleFactor

        // Center new image vertically in rect
        let newY = (newSize.height - newHeight) / 2

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: newY, width: newWidth, height: newHeight))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

class Math {
    static func lerp(start: Float, end: Float, t: Float) -> Float {
        return start + t * (end - start)
    }
}
