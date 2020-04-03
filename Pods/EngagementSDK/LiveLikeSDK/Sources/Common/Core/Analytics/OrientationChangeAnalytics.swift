//
//  OrientationChangeAnalytics.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 4/24/19.
//

import Foundation
import UIKit

enum Orientation: String {
    case portrait = "Portrait"
    case landscape = "Landscape"
    case undefined = "Undefined"
}

class OrientationChangeAnalytics {
    var shouldRecord: Bool = false

    private let eventRecorder: EventRecorder
    private let superPropertyRecorder: SuperPropertyRecorder
    private let peoplePropertyRecorder: PeoplePropertyRecorder

    // The last actual orientation
    private var currentOrientation: Orientation {
        didSet {
            currentOrientationUpdated(currentOrientation: currentOrientation)
        }
    }

    // The last valid orientation (portrait or landscape)
    private var lastValidOrientation: Orientation? {
        didSet {
            if let lastValidOrientation = lastValidOrientation {
                recordMixpanelProperties(deviceOrientation: lastValidOrientation)
            }
        }
    }

    private var timeValidOrientationChanged: Date?

    init(eventRecorder: EventRecorder, superPropertyRecorder: SuperPropertyRecorder, peoplePropertyRecorder: PeoplePropertyRecorder) {
        self.eventRecorder = eventRecorder
        self.superPropertyRecorder = superPropertyRecorder
        self.peoplePropertyRecorder = peoplePropertyRecorder
        if UIDevice.current.orientation.isPortrait {
            currentOrientation = .portrait
        } else if UIDevice.current.orientation.isLandscape {
            currentOrientation = .landscape
        } else {
            currentOrientation = .undefined
        }

        currentOrientationUpdated(currentOrientation: currentOrientation)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc private func orientationChanged() {
        // Handle orientation coming from undefined orientation
        if currentOrientation == .undefined {
            if UIDevice.current.orientation.isPortrait {
                currentOrientation = .portrait
            } else if UIDevice.current.orientation.isLandscape {
                currentOrientation = .landscape
            }
        }

        // Ignore case when coming from undefined state
        guard currentOrientation != .undefined else { return }
        // Ignore case when no valid orientation is defined
        guard let lastValidOrientation = lastValidOrientation else { return }
        guard let timeValidOrientationChanged = timeValidOrientationChanged else { return }

        if UIDevice.current.orientation.isPortrait {
            // Ignore unexpected cases where orientation notification raised without an actual change
            guard currentOrientation != .portrait else { return }
            if shouldRecord {
                eventRecorder.record(.orientationChanged(previousOrientation: lastValidOrientation, newOrientation: .portrait, secondsInPreviousOrientation: Date().timeIntervalSince(timeValidOrientationChanged)))
            }
            currentOrientation = .portrait
        } else if UIDevice.current.orientation.isLandscape {
            // Ignore unexpected cases where orientation notification raised without an actual change
            guard currentOrientation != .landscape else { return }
            if shouldRecord {
                eventRecorder.record(.orientationChanged(previousOrientation: lastValidOrientation, newOrientation: .landscape, secondsInPreviousOrientation: Date().timeIntervalSince(timeValidOrientationChanged)))
            }
            currentOrientation = .landscape
        }
    }

    private func currentOrientationUpdated(currentOrientation: Orientation) {
        if currentOrientation != .undefined {
            // If the last valid orientation is different from the current orientation set the time changed
            if lastValidOrientation != currentOrientation {
                timeValidOrientationChanged = Date()
            }
            lastValidOrientation = currentOrientation
        }
    }

    private func recordMixpanelProperties(deviceOrientation: Orientation) {
        superPropertyRecorder.register([.deviceOrientation(orientation: deviceOrientation)])
        peoplePropertyRecorder.record([.lastDeviceOrientation(orientation: deviceOrientation)])
    }
}
