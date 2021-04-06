import EngagementSDK
import UIKit

class CustomAlertWidgetViewController: Widget {
    private let model: AlertWidgetModel

    let timer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    var alertWidgetView: CustomAlertWidgetView {
        return view as! CustomAlertWidgetView
    }

    override init(model: AlertWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let alertView = CustomAlertWidgetView(
            title: model.title,
            text: model.text,
            mediaURL: model.imageURL,
            linkDescription: model.linkLabel
        )
        alertView.linkButton.addTarget(self, action: #selector(alertWidgetLinkButtonSelected), for: .touchUpInside)

        alertView.addSubview(timer)
        timer.bottomAnchor.constraint(equalTo: alertView.topAnchor).isActive = true
        timer.leadingAnchor.constraint(equalTo: alertView.leadingAnchor).isActive = true
        timer.trailingAnchor.constraint(equalTo: alertView.trailingAnchor).isActive = true
        timer.heightAnchor.constraint(equalToConstant: 5).isActive = true

        view = alertView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        timer.play(duration: model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) { [weak self] in
            guard let self = self else { return }
            self.delegate?.widgetDidEnterState(widget: self, state: .finished)
        }
        model.registerImpression()
        if model.linkURL != nil {
            model.markAsInteractive()
        }
    }

    @objc private func alertWidgetLinkButtonSelected() {
        self.model.openLinkUrl()
    }
}

class SponsoredAlertWidgetViewController: CustomAlertWidgetViewController {
    let sponsoredByLabel: UILabel = {
        let label = UILabel()
        label.text = "Sponsored by"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1.0)
        return label
    }()

    let sponsorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = #imageLiteral(resourceName: "jira-logo-scaled.png")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func loadView() {
        super.loadView()

        container.addSubview(sponsoredByLabel)
        container.addSubview(sponsorImageView)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 30),

            sponsoredByLabel.topAnchor.constraint(equalTo: container.topAnchor),
            sponsoredByLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sponsoredByLabel.trailingAnchor.constraint(equalTo: container.centerXAnchor, constant: -5),
            sponsoredByLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),

            sponsorImageView.topAnchor.constraint(equalTo: container.topAnchor),
            sponsorImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sponsorImageView.leadingAnchor.constraint(equalTo: container.centerXAnchor, constant: 5),
            sponsorImageView.widthAnchor.constraint(equalToConstant: 100)
        ])

        alertWidgetView.stackView.addArrangedSubview(container)
    }
}
