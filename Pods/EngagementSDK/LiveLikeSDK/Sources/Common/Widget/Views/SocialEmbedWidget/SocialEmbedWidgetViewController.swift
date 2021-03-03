//
//  SocialEmbedWidgetViewController.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 2/1/21.
//

import UIKit
import WebKit

class SocialEmbedWidgetViewController: Widget {

    private let model: SocialEmbedWidgetModel
    
    private var socialEmbedWidgetView: SocialEmbedWidgetView = {
        let widget = SocialEmbedWidgetView()
        widget.translatesAutoresizingMaskIntoConstraints = false
        return widget
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.style = UIActivityIndicatorView.Style.gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let onClickButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        return button
    }()
    
    private var closeButtonCompletion: ((WidgetViewModel) -> Void)?

    var didFinishLoadingContent: (() -> Void)?
    
    override var theme: Theme {
        didSet {
            self.applyTheme(theme)
        }
    }
    
    override var currentState: WidgetState {
        willSet {
            previousState = self.currentState
        }
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.widgetDidEnterState(widget: self, state: self.currentState)
                switch self.currentState {
                case .ready:
                    break
                case .interacting:
                    self.enterInteractingState()
                case .results:
                    self.enterResultsState()
                case .finished:
                    self.enterFinishedState()
                }
            }
        }
    }
    
    override init(model: SocialEmbedWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        theme = Theme()
        
        if let html = model.items.first?.oembed.html {
            let htmlContent = """
                <html>
                <header>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=YES">
                </header>
                \(html)
                </html>
            """
            socialEmbedWidgetView.contentView.loadHTMLString(htmlContent, baseURL: nil)
            socialEmbedWidgetView.contentView.navigationDelegate = self
        }
        
        model.registerImpression()
        socialEmbedWidgetView.titleView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
    }
    
    override func moveToNextState() {
        switch self.currentState {
        case .ready:
            self.currentState = .interacting
        case .interacting:
            self.currentState = .results
        case .results:
            self.currentState = .finished
        case .finished:
            break
        }
    }
    
    override func addCloseButton(_ completion: @escaping (WidgetViewModel) -> Void) {
        socialEmbedWidgetView.titleView.showCloseButton()
        closeButtonCompletion = completion
    }
    
    override func addTimer(seconds: TimeInterval, completion: @escaping (WidgetViewModel) -> Void) {
        self.socialEmbedWidgetView.titleView.beginTimer(
            duration: model.interactionTimeInterval,
            animationFilepath: theme.lottieFilepaths.timer
        ) { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }
    
    private func setUpUI() {
        
        view.addSubview(socialEmbedWidgetView)
        socialEmbedWidgetView.constraintsFill(to: view)
    
        if let title = model.comment {
            socialEmbedWidgetView.titleView.titleLabel.text = theme.uppercaseTitleText ? title.uppercased() : title
        } else {
            socialEmbedWidgetView.titleView.isHidden = true
        }
        
        view.addSubview(onClickButton)
        NSLayoutConstraint.activate([
            onClickButton.centerYAnchor.constraint(equalTo: socialEmbedWidgetView.contentView.centerYAnchor),
            onClickButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            onClickButton.widthAnchor.constraint(equalTo: socialEmbedWidgetView.widthAnchor),
            onClickButton.heightAnchor.constraint(equalTo: socialEmbedWidgetView.heightAnchor)
        ])
        onClickButton.addTarget(self, action: #selector(chatFlagPressed(sender:)), for: .touchUpInside)
        
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: socialEmbedWidgetView.contentView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        activityIndicator.startAnimating()
    }
    
    @objc private func chatFlagPressed(sender: UIButton) {
        guard let url = model.items.first?.url else { return }
        UIApplication.shared.open(url)
    }
    
    private func applyTheme(_ theme: Theme) {
        socialEmbedWidgetView.applyContainerProperties(theme.widgets.socialEmbed.main)
        socialEmbedWidgetView.titleView.titleMargins = theme.choiceWidgetTitleMargins
        socialEmbedWidgetView.titleView.applyContainerProperties(theme.widgets.socialEmbed.header)
        socialEmbedWidgetView.titleView.titleLabel.textColor = theme.widgets.socialEmbed.title.color
        socialEmbedWidgetView.titleView.titleLabel.font = theme.widgets.socialEmbed.title.font
        
        switch theme.widgets.socialEmbed.body.background {
        case .fill(let bgColor):
            socialEmbedWidgetView.coreWidgetView.backgroundColor = bgColor
        default:
            break
        }
        
    }
    
    @objc private func closeButtonPressed() {
        closeButtonCompletion?(self)
    }
    
    // MARK: Handle States
    private func enterInteractingState() {
        self.interactableState = .openToInteraction
        self.delegate?.widgetStateCanComplete(widget: self, state: .interacting)
    }
    
    private func enterResultsState() {
        self.interactableState = .closedToInteraction
        self.delegate?.widgetStateCanComplete(widget: self, state: .results)
    }
    
    private func enterFinishedState() {
        self.view.layoutIfNeeded()
        self.delegate?.widgetStateCanComplete(widget: self, state: .finished)
    }
}

extension SocialEmbedWidgetViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.frame.size.height = 1
        webView.frame.size = webView.scrollView.contentSize
        webView.scrollView.isScrollEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }

            self.activityIndicator.stopAnimating()
            UIView.animate(withDuration: 0.33, animations: {
                let webViewHeight = webView.scrollView.contentSize.height
                self.socialEmbedWidgetView.contentHeight = webViewHeight
                
                self.socialEmbedWidgetView.contentView.alpha = 1.0
                self.view.layoutIfNeeded()
                self.didFinishLoadingContent?()
            })
        }
    }
}
