import EngagementSDK
import UIKit

class CustomAlertWidgetViewController: Widget {
    private let model: AlertWidgetModel

    private var alertWidgetView: CustomAlertWidgetView {
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

        view = alertView
    }

    var viewDidAppear: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.alertWidgetView.timer.play(duration: self.model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) { [weak self] in
            guard let self = self else { return }
            self.delegate?.widgetDidEnterState(widget: self, state: .finished)
        }
    }

    @objc private func alertWidgetLinkButtonSelected() {
        guard let linkURL = model.linkURL else {
            return
        }
        UIApplication.shared.open(linkURL, options: [:], completionHandler: nil)
    }
}
