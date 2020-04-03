import UIKit
/// Example class that conforms to `GIFAnimatable`. Uses default values for the animator frame buffer count and resize behavior. You can either use it directly in your code or use it as a blueprint for your own subclass.
class GIFImageView: UIImageView, GIFAnimatable {
    /// A lazy animator.
    lazy var animator: Animator? = {
        Animator(withDelegate: self)
    }()

    /// Layer delegate method called periodically by the layer. **Should not** be called manually.
    ///
    /// - parameter layer: The delegated layer.
    override func display(_ layer: CALayer) {
        updateImageIfNeeded()
    }

    override var intrinsicContentSize: CGSize {
        return image?.size ?? CGSize.zero
    }
}
