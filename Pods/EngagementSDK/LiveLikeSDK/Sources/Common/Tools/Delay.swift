//
//  Delay.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-02-17.
//

import Foundation
func delay(_ delay: Double, closure: @escaping () -> Void) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}
