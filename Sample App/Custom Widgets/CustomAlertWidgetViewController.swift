import EngagementSDK
import UIKit

class CustomAlertWidgetViewController: Widget {
    private let model: AlertWidgetModel

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

        view = alertView
    }

    @objc private func alertWidgetLinkButtonSelected() {
        guard let linkURL = model.linkURL else {
            return
        }
        UIApplication.shared.open(linkURL, options: [:], completionHandler: nil)
    }
}
