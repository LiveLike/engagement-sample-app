//
//  WidgetTimelineViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 2/18/21.
//

import UIKit

/// A presentation mode for Widgets
///
/// Widgets in this mode will appear in a vertical list sorted by the time the Widget is created (descending).
///
/// On load, published widgets will be loaded from history and, by default, display results, and be non-interactive.
/// New widgets will appear at the top of the list and be interactive until the timer expires.
///
/// You can configure which and how widgets are displayed by overriding:
/// * didLoadInitialWidgets
/// * didLoadMoreWidgets
/// * didReceiveNewWidget
/// * makeWidget
open class WidgetTimelineViewController: UIViewController {

    public let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.isHidden = true
        return tableView
    }()

    public let session: ContentSession

    /// The list of loaded widgets sorted in descending order by the creation date
    public private(set) var widgetModels: [WidgetModel] = []

    /// Change to modify the behavior of the Default Widgets
    public var widgetStateController: WidgetViewDelegate = TimelineWidgetViewDelegate()

    public let snapToLiveButton: UIImageView = {
        let snapToLiveButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        snapToLiveButton.image = UIImage(named: "chatIcLive", in: Bundle(for: WidgetTimelineViewController.self), compatibleWith: nil)
        snapToLiveButton.translatesAutoresizingMaskIntoConstraints = false
        snapToLiveButton.alpha = 0.0
        snapToLiveButton.isUserInteractionEnabled = true
        return snapToLiveButton
    }()

    private let cellReuseIdentifer: String = "com.livelike.timelineCell"
    private var snapToLiveBottomConstraint: NSLayoutConstraint!
    private let emptyTableLoadingIndicator: UIView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        return spinner
    }()

    // Determines if the displayed widget should be interactable or not
    private var widgetIsInteractableByID: [String: Bool] = [:]
    
    /// Determines whether fetching data from backend is in progress
    private var isLoading: Bool = true
    
    public init(contentSession: ContentSession) {
        self.session = contentSession
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(emptyTableLoadingIndicator)
        view.addSubview(tableView)
        view.addSubview(snapToLiveButton)

        snapToLiveBottomConstraint = snapToLiveButton.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -16
        )
        NSLayoutConstraint.activate([
            emptyTableLoadingIndicator.topAnchor.constraint(equalTo: view.topAnchor),
            emptyTableLoadingIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyTableLoadingIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyTableLoadingIndicator.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            snapToLiveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            snapToLiveBottomConstraint
        ])

        tableView.register(WidgetTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifer)
        tableView.dataSource = self
        tableView.delegate = self

        snapToLiveButton.addGestureRecognizer({
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(snapToLive))
            tapGestureRecognizer.numberOfTapsRequired = 1
            return tapGestureRecognizer
        }())

        session.getPostedWidgetModels(page: .first) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case let .success(widgetModels):
                    guard let models = widgetModels else {
                        self.isLoading = false
                        self.tableView.isHidden = false
                        return
                    }
                    let filteredModels = self.didLoadInitialWidgets(models)
                    self.widgetModels.append(contentsOf: filteredModels)
                    filteredModels.forEach {
                        self.widgetIsInteractableByID[$0.id] = false
                    }

                    self.tableView.reloadData()
                    self.session.delegate = self
                case let .failure(error):
                    log.error(error)
                }
                self.isLoading = false
                self.tableView.isHidden = false
            }
        }
    }

    /// Called when the first page of widget history is successfully loaded.
    /// - Parameter widgetModels: The `WidgetModel`s that were loaded
    /// - Returns:The `WidgetModels` to be added to the timeline
    open func didLoadInitialWidgets(_ widgetModels: [WidgetModel]) -> [WidgetModel] {
        return widgetModels
    }

    /// Called when the next page of widget history is successfully loaded.
    /// - Parameter widgetModels: The `WidgetModels` that were loaded
    /// - Returns:The `WidgetModels` to be added to the timeline
    open func didLoadMoreWidgets(_ widgetModels: [WidgetModel]) -> [WidgetModel] {
        return widgetModels
    }

    /// Called when a new widget is published.
    /// - Parameter widgetModel: The `WidgetModel` that was received
    /// - Returns: The `WidgetModel` to be added to the timeline. Return `nil` to ignore this `WidgetModel`
    open func didReceiveNewWidget(_ widgetModel: WidgetModel) -> WidgetModel? {
        return widgetModel
    }

    /// A factory method that is called when a widget is ready to be displayed.
    /// - Parameter widgetModel: The `WidgetModel` to be displayed
    /// - Returns: A `UIViewController` that represents the Widget. Return `nil` to ignore this widget.
    open func makeWidget(_ widgetModel: WidgetModel) -> UIViewController? {
        var widget: Widget?
        switch widgetModel {
        case .socialEmbed(let model):
            let socialEmbedWidget = SocialEmbedWidgetViewController(model: model)
            socialEmbedWidget.didFinishLoadingContent = { [weak self] in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            }
            widget = socialEmbedWidget
        default:
            widget = DefaultWidgetFactory.makeWidget(from: widgetModel)
        }

        /// Set interactivity
        widget?.delegate = widgetStateController
        if widgetIsInteractableByID[widgetModel.id] ?? false {
            widget?.moveToNextState()
        } else {
            widget?.currentState = .finished
        }

        widgetIsInteractableByID[widgetModel.id] = false
        return widget
    }

    private func snapToLiveIsHidden(_ isHidden: Bool) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.snapToLiveBottomConstraint?.constant = isHidden ? self.snapToLiveButton.bounds.height : -16
            self.view.layoutIfNeeded()
            self.snapToLiveButton.alpha = isHidden ? 0 : 1
        }, completion: nil)
    }

    @objc func snapToLive() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    private func createLoadingFooterView() -> UIView {
        let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        let spinner = UIActivityIndicatorView()
        spinner.center = loadingView.center
        loadingView.addSubview(spinner)
        spinner.startAnimating()
        
        return loadingView
    }

    // MARK: - Helpers
    private class WidgetTableViewCell: UITableViewCell {
        var widget: UIViewController?
    }
}

// MARK: - ContentSessionDelegate

///:nodoc:
extension WidgetTimelineViewController: ContentSessionDelegate {
    public func playheadTimeSource(_ session: ContentSession) -> Date? { return nil }
    public func session(_ session: ContentSession, didChangeStatus status: SessionStatus) {}
    public func session(_ session: ContentSession, didReceiveError error: Error) {}
    public func chat(session: ContentSession, roomID: String, newMessage message: ChatMessage) {}
    public func widget(_ session: ContentSession, didBecomeReady widget: Widget) {}
    open func contentSession(_ session: ContentSession, didReceiveWidget widget: WidgetModel) {
        DispatchQueue.main.async {
            guard let widgetModel = self.didReceiveNewWidget(widget) else { return }
            self.widgetModels.insert(widgetModel, at: 0)
            self.widgetIsInteractableByID[widgetModel.id] = true
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        }
    }
}

// MARK: - UITableViewDelegate

///:nodoc:
extension WidgetTimelineViewController: UITableViewDelegate {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if
            let firstVisibleRow = self.tableView.indexPathsForVisibleRows?.first?.row,
            firstVisibleRow > 0
        {
            self.snapToLiveIsHidden(false)
        } else {
            self.snapToLiveIsHidden(true)
        }
        
        /// Handle infinite scroll
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if offsetY > contentHeight - scrollView.frame.height && !isLoading {
            self.isLoading = true
            self.tableView.tableFooterView = createLoadingFooterView()
            session.getPostedWidgetModels(page: .next) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case let .success(models):
                        guard let models = models else {
                            self.isLoading = false
                            self.tableView.tableFooterView = nil
                            return
                        }
                        let widgetModels = self.didLoadMoreWidgets(models)
                        let indexPaths: [IndexPath] = widgetModels.enumerated().map {
                            return IndexPath(row: self.widgetModels.count + $0.offset, section: 0)
                        }
                        self.widgetModels.append(contentsOf: widgetModels)
                        widgetModels.forEach {
                            self.widgetIsInteractableByID[$0.id] = false
                        }
                        UIView.setAnimationsEnabled(false)
                        self.tableView.insertRows(at: indexPaths, with: .none)
                        UIView.setAnimationsEnabled(true)
                    case let .failure(error):
                        log.error(error)
                    }
                    self.isLoading = false
                    self.tableView.tableFooterView = nil
                }

            }
        }
    }
}

// MARK: - UITableViewDataSource

///:nodoc:
extension WidgetTimelineViewController: UITableViewDataSource {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return widgetModels.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifer) as? WidgetTableViewCell else {
            return UITableViewCell()
        }
        // prepare for reuse
        cell.widget?.removeFromParent()
        cell.widget?.view.removeFromSuperview()
        cell.widget = nil

        let widgetModel = widgetModels[indexPath.row]

        if let widget = self.makeWidget(widgetModel) {
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
            cell.widget = widget
        }

        return cell
    }
}
