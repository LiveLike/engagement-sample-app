//
//  Debouncer.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-03-25.
//

import Foundation

class Debouncer<T> {
    var callback: ((T) -> Void)?
    let delay: Double
    weak var timer: Timer?

    init(delay: Double) {
        self.delay = delay
    }

    deinit {
        timer?.invalidate()
    }

    func call(value: T) {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { timer in
            self.callback?(value)
            timer.invalidate()
        })
        timer = nextTimer
    }
}
