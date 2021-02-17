import UIKit

public final class WidgetViewHelpers {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.dateFormat = "MMM d, hh:mma"
        return dateFormatter
    }()

    static func getTimestampString(_ date: Date) -> String {
        return WidgetViewHelpers.dateFormatter.string(from: date).uppercased()
    }

    static let colors: Colors = Colors()

    class Colors {
        let green = UIColor(red: 0/255, green: 194/255, blue: 101/255, alpha: 1.0)
        var red: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 244/255, green: 54/255, blue: 37/255, alpha: 1.0)
                    default:
                        return UIColor(red: 228/255, green: 30/255, blue: 12/255, alpha: 1.0)
                    }
                }
            } else {
                return UIColor(red: 228/255, green: 30/255, blue: 12/255, alpha: 1.0)
            }
        }
        var blue: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 29/255, green: 161/255, blue: 241/255, alpha: 1.0)
                    default:
                        return UIColor(red: 0/255, green: 121/255, blue: 194/255, alpha: 1.0)
                    }
                }
            } else {
                return UIColor(red: 0/255, green: 121/255, blue: 194/255, alpha: 1.0)
            }
        }
        var gray: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 93/255, green: 95/255, blue: 107/255, alpha: 1.0)
                    default:
                        return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
                    }
                }
            } else {
                return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
            }
        }
        let white = UIColor(red: 253/255, green: 253/255, blue: 253/255, alpha: 1.0)
        let black = UIColor(red: 23 / 255, green: 23 / 255, blue: 29 / 255, alpha: 1.0)
        var background: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return self.black
                    default:
                        return self.white
                    }
                }
            } else {
                return self.white
            }
        }
        
        var label: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return self.white
                    default:
                        return self.black
                    }
                }
            } else {
                return self.black
            }
        }
    }

    static let fonts: Fonts = Fonts()

    class Fonts {
        let title: UIFont? = .systemFont(ofSize: 15, weight: .black)
        let optionText: UIFont? = .systemFont(ofSize: 13, weight: .regular)
        let optionPercentage: UIFont? = .systemFont(ofSize: 20, weight: .bold)
        let timestamp: UIFont? = .systemFont(ofSize: 10, weight: .regular)
        let alertBody: UIFont? = .systemFont(ofSize: 14, weight: .regular)
        let alertLink: UIFont? = .systemFont(ofSize: 16, weight: .regular)
        let cheerMeterOption: UIFont? = .systemFont(ofSize: 14, weight: .regular)
    }

    static func setImage(_ imageURL: URL, on imageView: UIImageView) {
        URLSession.shared.dataTask(with: imageURL) { data, _, error in
            if let error = error {
                print("Failed to load image from url: \(error)")
                return
            }
            DispatchQueue.main.async {
                if let data = data {
                    if let image = UIImage(data: data) {
                        imageView.image = image
                    }
                }
            }
        }.resume()
    }
}
