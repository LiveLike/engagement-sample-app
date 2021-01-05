import Lottie
import UIKit

class CustomAlertWidgetView: UIView {
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        return stackView
    }()

    let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let alertTag: UILabel = {
        let label = UILabel()
        label.text = "ALERT"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let bodyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let mediaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let footerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let linkButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.textColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(
        title: String?,
        text: String?,
        mediaURL: URL?,
        linkDescription: String?
    ) {
        super.init(frame: .zero)

        backgroundColor = .white

        addSubview(stackView)
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(bodyView)
        stackView.addArrangedSubview(footerView)

        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 21).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -21).isActive = true

        headerView.addSubview(alertTag)
        alertTag.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        alertTag.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        alertTag.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        alertTag.heightAnchor.constraint(equalToConstant: 12).isActive = true

        if title != nil {
            headerView.addSubview(titleLabel)
            titleLabel.topAnchor.constraint(equalTo: alertTag.bottomAnchor, constant: 4).isActive = true
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
            titleLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        }

        // Text and Media
        if text != nil, mediaURL != nil {
            bodyView.addSubview(textLabel)
            bodyView.addSubview(mediaImageView)

            bodyView.heightAnchor.constraint(equalToConstant: 90).isActive = true

            textLabel.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor).isActive = true
            textLabel.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor).isActive = true
            textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
            textLabel.widthAnchor.constraint(equalToConstant: 155).isActive = true

            mediaImageView.topAnchor.constraint(equalTo: bodyView.topAnchor).isActive = true
            mediaImageView.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor).isActive = true
            mediaImageView.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor).isActive = true
            mediaImageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        }

        // Text only
        if text != nil, mediaURL == nil {
            bodyView.addSubview(textLabel)
            bodyView.heightAnchor.constraint(equalToConstant: 90).isActive = true
            textLabel.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor).isActive = true
            textLabel.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor).isActive = true
            textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        }

        // Media only
        if mediaURL != nil, text == nil {
            bodyView.addSubview(mediaImageView)
            mediaImageView.topAnchor.constraint(equalTo: bodyView.topAnchor).isActive = true
            mediaImageView.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor).isActive = true
            mediaImageView.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor).isActive = true
            mediaImageView.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor).isActive = true
            mediaImageView.heightAnchor.constraint(equalTo: bodyView.widthAnchor, multiplier: 1 / 2).isActive = true
        }

        if linkDescription != nil {
            footerView.addSubview(linkButton)
            linkButton.topAnchor.constraint(equalTo: footerView.topAnchor).isActive = true
            linkButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor).isActive = true
            linkButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor).isActive = true
            linkButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor).isActive = true
        }

        titleLabel.text = title
        textLabel.text = text
        linkButton.setTitle(linkDescription, for: .normal)

        do {
            if let mediaURL = mediaURL {
                let mediaData = try Data(contentsOf: mediaURL)
                let mediaImage = UIImage(data: mediaData)
                mediaImageView.image = mediaImage
            }
        } catch {
            print(error)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
