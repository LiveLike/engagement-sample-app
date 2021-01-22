//
//  CustomImageSliderViewController.swift
//  Sample App
//
//  Created by Jelzon Monzon on 1/6/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import EngagementSDK
import Lottie
import UIKit

class CustomImageSliderViewController: Widget {
    private let model: ImageSliderWidgetModel

    let timer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    var magnitudeIndicatorLeadingConstraint: NSLayoutConstraint?

    let magnitudeIndicator: AnimationView = {
        let animationView = AnimationView(name: "image-slider-avg")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    private var thumbImages: [UIImage] = []

    private var imageSliderView: CustomImageSliderView {
        return view as! CustomImageSliderView
    }

    override init(model: ImageSliderWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let imageSliderView = CustomImageSliderView()

        imageSliderView.titleLabel.text = model.question
        model.options.forEach { option in
            guard let imageData = try? Data(contentsOf: option.imageURL) else { return }
            let thumbSize = CGSize(width: 40, height: 40)
            guard let image = UIImage(data: imageData) else { return }
            UIGraphicsBeginImageContextWithOptions(thumbSize, false, 0.0)
            image.draw(in: CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height))
            guard let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
            UIGraphicsEndImageContext()
            thumbImages.append(scaledImage)
        }

        imageSliderView.slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        imageSliderView.slider.addSubview(magnitudeIndicator)
        magnitudeIndicator.centerYAnchor.constraint(equalTo: imageSliderView.slider.centerYAnchor).isActive = true
        magnitudeIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        magnitudeIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true

        imageSliderView.addSubview(timer)
        timer.bottomAnchor.constraint(equalTo: imageSliderView.topAnchor).isActive = true
        timer.leadingAnchor.constraint(equalTo: imageSliderView.leadingAnchor).isActive = true
        timer.trailingAnchor.constraint(equalTo: imageSliderView.trailingAnchor).isActive = true
        timer.heightAnchor.constraint(equalToConstant: 5).isActive = true

        view = imageSliderView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let newThumbImage = getThumbImage()
        imageSliderView.slider.setThumbImage(newThumbImage, for: .normal)

        model.delegate = self

        timer.play(duration: model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) { [weak self] in
            guard let self = self else { return }
            self.model.lockInVote(magnitude: Double(self.imageSliderView.slider.value)) { _ in
                self.updateMagnitudeIndicator(self.model.averageMagnitude)
                self.magnitudeIndicator.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    self.delegate?.widgetDidEnterState(widget: self, state: .finished)
                }
            }
        }
        model.registerImpression()
    }

    func updateMagnitudeIndicator(_ magnitude: Double) {
        magnitudeIndicatorLeadingConstraint?.isActive = false

        let averageXPosition = CGFloat(magnitude) * imageSliderView.slider.bounds.width
        magnitudeIndicatorLeadingConstraint = magnitudeIndicator.centerXAnchor.constraint(
            equalTo: imageSliderView.slider.leadingAnchor,
            constant: averageXPosition
        )
        magnitudeIndicatorLeadingConstraint?.isActive = true
    }

    @objc private func sliderValueChanged() {
        let newThumbImage = getThumbImage()
        imageSliderView.slider.setThumbImage(newThumbImage, for: .normal)
    }

    private func getThumbImage() -> UIImage {
        if thumbImages.count == 1 {
            return thumbImages[0]
        } else {
            let imageIndex: Int = Int(round(imageSliderView.slider.value * Float(thumbImages.count - 1)))
            return thumbImages[imageIndex]
        }
    }
}

extension CustomImageSliderViewController: ImageSliderWidgetModelDelegate {
    func imageSliderWidgetModel(_ model: ImageSliderWidgetModel, averageMagnitudeDidChange averageMagnitude: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateMagnitudeIndicator(averageMagnitude)
        }
    }
}
