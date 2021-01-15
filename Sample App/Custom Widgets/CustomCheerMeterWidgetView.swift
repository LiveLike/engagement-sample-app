import Lottie
import UIKit

class CustomCheerMeterWidgetView: UIView {
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

    let widgetTypeLabel: UILabel = {
        let label = UILabel()
        label.text = "CHEER METER"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let bodyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let versusAnimationView: AnimationView = {
        let animationView = AnimationView(name: "vs-1-light")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    let optionViewA: CustomCheerMeterWidgetOptionView = {
        let optionView = CustomCheerMeterWidgetOptionView()
        optionView.translatesAutoresizingMaskIntoConstraints = false
        return optionView
    }()

    let optionLabelA: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let optionViewB: CustomCheerMeterWidgetOptionView = {
        let optionView = CustomCheerMeterWidgetOptionView()
        optionView.translatesAutoresizingMaskIntoConstraints = false
        return optionView
    }()

    let optionLabelB: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = .white

        addSubview(stackView)
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(bodyView)

        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 21).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -21).isActive = true

        headerView.addSubview(widgetTypeLabel)
        widgetTypeLabel.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        widgetTypeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        widgetTypeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        widgetTypeLabel.heightAnchor.constraint(equalToConstant: 12).isActive = true

        headerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: widgetTypeLabel.bottomAnchor, constant: 4).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18).isActive = true

        bodyView.addSubview(optionViewA)
        optionViewA.topAnchor.constraint(equalTo: bodyView.topAnchor).isActive = true
        optionViewA.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 30).isActive = true
        optionViewA.heightAnchor.constraint(equalToConstant: 100).isActive = true
        optionViewA.widthAnchor.constraint(equalToConstant: 100).isActive = true

        bodyView.addSubview(optionLabelA)
        optionLabelA.topAnchor.constraint(equalTo: optionViewA.bottomAnchor, constant: 5).isActive = true
        optionLabelA.leadingAnchor.constraint(equalTo: optionViewA.leadingAnchor).isActive = true
        optionLabelA.trailingAnchor.constraint(equalTo: optionViewA.trailingAnchor).isActive = true
        optionLabelA.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor).isActive = true
        optionLabelA.heightAnchor.constraint(equalToConstant: 17).isActive = true

        bodyView.addSubview(optionViewB)
        optionViewB.topAnchor.constraint(equalTo: bodyView.topAnchor).isActive = true
        optionViewB.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor, constant: -30).isActive = true
        optionViewB.heightAnchor.constraint(equalToConstant: 100).isActive = true
        optionViewB.widthAnchor.constraint(equalToConstant: 100).isActive = true

        bodyView.addSubview(optionLabelB)
        optionLabelB.topAnchor.constraint(equalTo: optionViewB.bottomAnchor, constant: 5).isActive = true
        optionLabelB.leadingAnchor.constraint(equalTo: optionViewB.leadingAnchor).isActive = true
        optionLabelB.trailingAnchor.constraint(equalTo: optionViewB.trailingAnchor).isActive = true
        optionLabelB.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor).isActive = true
        optionLabelB.heightAnchor.constraint(equalToConstant: 17).isActive = true

        bodyView.addSubview(versusAnimationView)
        versusAnimationView.topAnchor.constraint(equalTo: bodyView.topAnchor).isActive = true
        versusAnimationView.bottomAnchor.constraint(equalTo: optionViewA.bottomAnchor).isActive = true
        versusAnimationView.leadingAnchor.constraint(equalTo: optionViewA.trailingAnchor).isActive = true
        versusAnimationView.trailingAnchor.constraint(equalTo: optionViewB.leadingAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CustomCheerMeterWidgetOptionView: UIView {
    let button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let progressBarHeightConstraint: NSLayoutConstraint

    let progressBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init() {
        progressBarHeightConstraint = progressBar.heightAnchor.constraint(equalToConstant: 0)
        super.init(frame: .zero)

        layer.cornerRadius = 4
        layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0).cgColor
        layer.borderWidth = 1
        clipsToBounds = true

        addSubview(progressBar)
        addSubview(imageView)
        addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.topAnchor.constraint(equalTo: button.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -20),

            progressBar.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            progressBar.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            progressBarHeightConstraint
        ])

        button.addTarget(self, action: #selector(touchDown), for: .touchDown)
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateProgress(percent: CGFloat) {
        progressBarHeightConstraint.constant = percent * bounds.height
        UIView.animate(withDuration: 0.5) {
            self.layoutIfNeeded()
        }
    }

    @objc private func touchDown() {
        backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
    }

    @objc private func touchUpInside() {
        backgroundColor = .white
    }
}
