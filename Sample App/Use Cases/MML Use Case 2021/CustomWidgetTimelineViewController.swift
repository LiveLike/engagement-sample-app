//
//  CustomWidgetTimelineViewController.swift
//  LiveLikeTestApp
//
//  Created by Jelzon Monzon on 1/18/21.
//

import EngagementSDK
import UIKit

class CustomWidgetTimelineViewController: UIViewController {
    private let cellReuseIdentifer: String = "myCell"
    private let session: ContentSession

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = false
        return tableView
    }()

    // Determines if the displayed widget should be interactable or not
    private var widgetIsInteractableByID: [String: Bool] = [:]
    private var widgetModels: [WidgetModel] = []

    init(session: ContentSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        view.backgroundColor = .lightGray

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifer)
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
                }
            case let .failure(error):
                print(error)
            }
            self.session.delegate = self
        }
    }

    func makeInteractableWidget(widgetModel: WidgetModel) -> UIViewController? {
        return DefaultWidgetFactory.makeWidget(from: widgetModel)
    }

    func makeResultsWidget(widgetModel: WidgetModel) -> UIViewController? {
        return DefaultWidgetFactory.makeWidget(from: widgetModel)
    }
}

extension CustomWidgetTimelineViewController: ContentSessionDelegate {
    func playheadTimeSource(_ session: ContentSession) -> Date? { return nil }
    func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {}
    func session(_ session: ContentSession, didReceiveError error: Error) {}
    func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {}
    func widget(_ session: ContentSession, didBecomeReady widget: Widget) {}

    func contentSession(_ session: ContentSession, didReceiveWidget widget: WidgetModel) {
        widgetModels.insert(widget, at: 0)
        widgetIsInteractableByID[widget.id] = true
        DispatchQueue.main.async {
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }
}

extension CustomWidgetTimelineViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return widgetModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifer) else {
            return UITableViewCell()
        }

        // prepare for reuse
        cell.contentView.subviews.forEach {
            $0.removeFromSuperview()
        }

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

            NSLayoutConstraint.activate([
                widget.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                widget.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                widget.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                widget.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])

            widgetIsInteractableByID[widgetModel.id] = false
        }

        return cell
    }
}
