import UIKit

class CustomWidgetBarTimer: UIView {
    var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 250/255, green: 200/255, blue: 60/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var progressViewWidtchConstraint: NSLayoutConstraint!

    private var totalDuration: TimeInterval?
    private var endTime: Date?

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear

        addSubview(progressView)
        self.progressViewWidtchConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressViewWidtchConstraint
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didBecomeActive() {
        guard let totalDuration = totalDuration, let endTime = endTime else { return }
        guard totalDuration > 0 else { return }
        let remainingDuration: TimeInterval = endTime.timeIntervalSince1970 - Date().timeIntervalSince1970
        let elapsedDurationPercent = (totalDuration - remainingDuration) / totalDuration

        if remainingDuration > 0 {
            self.progressViewWidtchConstraint.constant = CGFloat(elapsedDurationPercent) * self.bounds.width
            self.layoutIfNeeded()
            self.progressView.isHidden = false

            UIView.animate(withDuration: remainingDuration, delay: 0, options: .curveLinear, animations: { [weak self] in
                guard let self = self else { return }
                self.progressViewWidtchConstraint.constant = self.bounds.width
                self.layoutIfNeeded()
            }, completion: { _ in
                self.progressView.isHidden = true
            })
        }
    }

    func play(duration: TimeInterval) {
        self.totalDuration = duration
        self.endTime = Date() + duration
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { [weak self] in
                guard let self = self else { return }
                self.progressViewWidtchConstraint.constant = self.bounds.width
                self.layoutIfNeeded()
            }, completion: { _ in
                self.progressView.isHidden = true
            })
        }
    }
}
