import UIKit

class CustomWidgetBarTimer: UIView {
    var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 250/255, green: 200/255, blue: 60/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var progressViewTrailingConstraintToSuperviewLeadingAnchor: NSLayoutConstraint!
    var progressViewTrailingConstraintToSuperviewTrailingAnchor: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        backgroundColor = .white

        addSubview(progressView)
        progressViewTrailingConstraintToSuperviewLeadingAnchor = progressView.trailingAnchor.constraint(equalTo: leadingAnchor)
        progressViewTrailingConstraintToSuperviewTrailingAnchor = progressView.trailingAnchor.constraint(equalTo: trailingAnchor)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressViewTrailingConstraintToSuperviewLeadingAnchor
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play(duration: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressViewTrailingConstraintToSuperviewTrailingAnchor.isActive = false
            self.progressViewTrailingConstraintToSuperviewLeadingAnchor.isActive = true
            self.layoutIfNeeded()

            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) { [weak self] in
                guard let self = self else { return }
                self.progressViewTrailingConstraintToSuperviewTrailingAnchor.isActive = true
                self.progressViewTrailingConstraintToSuperviewLeadingAnchor.isActive = false
                self.layoutIfNeeded()
            }
        }
    }
}
