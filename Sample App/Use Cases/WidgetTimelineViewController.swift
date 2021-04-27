import EngagementSDK
import UIKit

public final class WidgetTimelineViewController: UIViewController {
    private let cellReuseIdentifer: String = "myCell"
    private let session: ContentSession

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.isHidden = true
        return tableView
    }()

    // Determines if the displayed widget should be interactable or not
    private var widgetIsInteractableByID: [String: Bool] = [:]
    private var widgetModels: [WidgetModel] = []

    public init(session: ContentSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        super.loadView()

        view.backgroundColor = WidgetViewHelpers.colors.background

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(WidgetTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifer)
        tableView.dataSource = self

        session.getPostedWidgetModels(page: .first) { result in
            switch result {
            case let .success(widgetModels):
                guard let widgetModels = widgetModels else { return }
                self.widgetModels.append(contentsOf: widgetModels)
                widgetModels.forEach {
                    self.widgetIsInteractableByID[$0.id] = false
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                }
            case let .failure(error):
                print(error)
            }
            self.session.delegate = self
        }
    }

    func makeInteractableWidget(widgetModel: WidgetModel) -> UIViewController? {
        switch widgetModel {
        case let .poll(model):
            if model.containsImages {
                return CustomImagePollWidgetViewController(model: model)
            }
            return CustomTextPollWidgetViewController(model: model)
        case let .quiz(model):
            if model.containsImages {
                return CustomImageQuizWidgetViewController(model: model)
            }
            return CustomTextQuizWidgetViewController(model: model)
        case let .imageSlider(model):
            return CustomImageSliderViewController(model: model)
        case let .alert(model):
            return CustomAlertWidgetViewController(model: model)
        case let .cheerMeter(model):
            guard model.options.count == 2 else { return nil }
            return CustomCheerMeterWidgetViewController(model: model)
        case let .prediction(model):
            if model.containsImages {
                return CustomImagePredictionWidget(model: model)
            } else {
                return CustomTextPredictionWidgetViewController(model: model)
            }
        case let .predictionFollowUp(model):
            if model.containsImages {
                return CustomImgPredictionFollowUpWidgetVC(model: model)
            } else {
                return CustomTextPredictionFollowUpWidgetViewController(model: model)
            }
        case .socialEmbed(_):
            return DefaultWidgetFactory.makeWidget(from: widgetModel)
        }
    }

    func makeResultsWidget(widgetModel: WidgetModel) -> UIViewController? {
        switch widgetModel {
        case let .poll(model):
            if model.containsImages {
                return ImagePollWidgetResultsViewController(model: model)
            }
            return TextPollWidgetResultsViewController(model: model)
        case let .quiz(model):
            if model.containsImages {
                return ImageQuizWidgetResultsViewController(model: model)
            }
            return TextQuizWidgetResultsViewController(model: model)
        case let .imageSlider(model):
            return ImageSliderResultsViewController(model: model)
        case let .alert(model):
            let widget = CustomAlertWidgetViewController(model: model)
            widget.timer.isHidden = true
            return widget
        case let .cheerMeter(model):
            guard model.options.count == 2 else { return nil }
            return CheerMeterWidgetResultsViewController(model: model)
        case let .prediction(model):
            if model.containsImages {
                return ImagePredictionWidgetResultsViewController(model: model)
            } else {
                return TextPredictionWidgetResultsViewController(model: model)
            }
        case let .predictionFollowUp(model):
            if model.containsImages {
                return ImagePredictionFollowUpResultsViewController(model: model)
            } else {
                return TextPredictionFollowUpResultsViewController(model: model)
            }
        case .socialEmbed(_):
            return DefaultWidgetFactory.makeWidget(from: widgetModel)
        }
    }
}

extension WidgetTimelineViewController: ContentSessionDelegate {
    public func playheadTimeSource(_ session: ContentSession) -> Date? { return nil }
    public func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {}
    public func session(_ session: ContentSession, didReceiveError error: Error) {}
    public func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {}
    public func widget(_ session: ContentSession, didBecomeReady widget: Widget) {}

    public func contentSession(_ session: ContentSession, didReceiveWidget widget: WidgetModel) {
        widgetModels.insert(widget, at: 0)
        widgetIsInteractableByID[widget.id] = true
        DispatchQueue.main.async {
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }
}

extension WidgetTimelineViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return widgetModels.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifer) as? WidgetTableViewCell else {
            return UITableViewCell()
        }

        // prepare for reuse
        cell.widget?.removeFromParent()
        cell.widget?.view.removeFromSuperview()
        cell.widget = nil

        let widgetModel = widgetModels[indexPath.row]

        var widget: UIViewController?
        if widgetIsInteractableByID[widgetModel.id] ?? false {
            widget = makeInteractableWidget(widgetModel: widgetModel)
        } else {
            widget = makeResultsWidget(widgetModel: widgetModel)
        }

        if let widget = widget {
            addChild(widget)
            widget.didMove(toParent: self)
            widget.view.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(widget.view)
            cell.contentView.backgroundColor = WidgetViewHelpers.colors.background

            NSLayoutConstraint.activate([
                widget.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                widget.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                widget.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                widget.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10)
            ])

            widgetIsInteractableByID[widgetModel.id] = false
        }

        cell.widget = widget

        return cell
    }
}

class WidgetTableViewCell: UITableViewCell {
    var widget: UIViewController?
}
