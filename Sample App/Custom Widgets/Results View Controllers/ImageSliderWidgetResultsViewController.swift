import EngagementSDK
import Lottie
import UIKit

class ImageSliderResultsViewController: Widget {
    private let model: ImageSliderWidgetModel

    override init(model: ImageSliderWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let imageSliderView = CustomImageSliderView()

        imageSliderView.slider.isUserInteractionEnabled = false
        imageSliderView.titleLabel.text = model.question

        let averageImageIndex: Int = Int(round(Float(model.averageMagnitude) * Float(model.options.count - 1)))
        URLSession.shared.dataTask(with: model.options[averageImageIndex].imageURL) { data, _, error in
            if let error = error {
                print("Failed to load image from url: \(error)")
                return
            }
            DispatchQueue.main.async {
                if let data = data {
                    if let image = UIImage(data: data) {
                        let thumbSize = CGSize(width: 40, height: 40)
                        UIGraphicsBeginImageContextWithOptions(thumbSize, false, 0.0)
                        image.draw(in: CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height))
                        guard let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
                        UIGraphicsEndImageContext()
                        imageSliderView.slider.setThumbImage(scaledImage, for: .normal)
                    }
                }
            }
        }.resume()

        imageSliderView.slider.value = Float(model.averageMagnitude)

        view = imageSliderView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.registerImpression()
    }
}
