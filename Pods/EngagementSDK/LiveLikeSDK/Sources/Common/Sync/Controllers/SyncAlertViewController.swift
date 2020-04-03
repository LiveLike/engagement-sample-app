//
//  SyncAlertViewController.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-15.
//

import UIKit

class SyncAlertViewController: UIViewController {
    // MAKR: IBOutlets
    @IBOutlet var alertView: UIView!
    @IBOutlet var pinLabel: UILabel!
    @IBOutlet var timeoutLabel: UILabel!

    // MARK: Private Variables

    private var timer: Timer?
    private var timeout: TimeInterval = 60.0

    private var pin: String?

    // MARK: Initializers

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTimeoutLabel()
        pinLabel.text = pin

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeoutUpdates), userInfo: nil, repeats: true)
    }

    @objc private func timeoutUpdates() {
        timeout -= 1
        updateTimeoutLabel()
        if timeout <= 0.0 {
            dismiss(animated: true, completion: nil)
        }
    }

    private func updateTimeoutLabel() {
        timeoutLabel.text = "Time left: \(Int(round(timeout)))"
    }

    @IBAction func okButtonPressed(_ sender: Any) {
        timer?.invalidate()
        timer = nil
        dismiss(animated: true, completion: nil)
    }
}

extension SyncAlertViewController {
    static func instantiate(pin: String, timeout: TimeInterval = 60.0) -> SyncAlertViewController? {
        let storyboard = UIStoryboard(name: "Sync", bundle: Bundle(for: self))
        guard let viewController = storyboard.instantiateInitialViewController() as? SyncAlertViewController else {
            assertionFailure("SyncAlertViewController can not be loaded")
            return nil
        }

        viewController.providesPresentationContextTransitionStyle = true
        viewController.definesPresentationContext = true
        viewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        viewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve

        viewController.timeout = timeout
        viewController.pin = pin

        return viewController
    }
}
