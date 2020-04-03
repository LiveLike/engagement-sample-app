import UIKit
/// A `UIImage` extension that makes it easier to resize the image and inspect its size.
extension UIImage {
    /// Resizes an image instance.
    ///
    /// - parameter size: The new size of the image.
    /// - returns: A new resized image instance.
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }

    /// Resizes an image instance to fit inside a constraining size while keeping the aspect ratio.
    ///
    /// - parameter size: The constraining size of the image.
    /// - returns: A new resized image instance.
    func constrained(by size: CGSize) -> UIImage {
        let newSize = size.constrained(by: size)
        return resized(to: newSize)
    }

    /// Resizes an image instance to fill a constraining size while keeping the aspect ratio.
    ///
    /// - parameter size: The constraining size of the image.
    /// - returns: A new resized image instance.
    func filling(size: CGSize) -> UIImage {
        let newSize = size.filling(size)
        return resized(to: newSize)
    }

    /// Returns a new `UIImage` instance using raw image data and a size.
    ///
    /// - parameter data: Raw image data.
    /// - parameter size: The size to be used to resize the new image instance.
    /// - returns: A new image instance from the passed in data.
    class func image(with data: Data, size: CGSize) -> UIImage? {
        return UIImage(data: data)?.resized(to: size)
    }

    /// Returns an image size from raw image data.
    ///
    /// - parameter data: Raw image data.
    /// - returns: The size of the image contained in the data.
    class func size(withImageData data: Data) -> CGSize? {
        return UIImage(data: data)?.size
    }
    
    static func coloredImage(from color: UIColor?, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        defer {
            UIGraphicsEndImageContext()
        }

        let context = UIGraphicsGetCurrentContext()
        color?.setFill()
        context?.fill(CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func isAnimatedImage() -> Bool {
        if let imageData = self.pngData() {
            if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
                let count = CGImageSourceGetCount(source)
                return count > 1
            }
            return false
        }
        return false
    }
}
