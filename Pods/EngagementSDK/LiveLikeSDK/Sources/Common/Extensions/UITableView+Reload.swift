//
//  UITableView+Reload.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-03-26.
//

import UIKit

extension UITableView {
    func insertMessages(at indexPaths: [IndexPath], updateData: () -> Void, completion: @escaping (Bool) -> Void) {
        if #available(iOS 11.0, *) {
            UIView.setAnimationsEnabled(false)
            performBatchUpdates({
                updateData()
                self.insertRows(at: indexPaths, with: .bottom)
            }, completion: { finished in
                completion(finished)
                UIView.setAnimationsEnabled(true)
            })

        } else {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                completion(true)
            }
            updateData()
            beginUpdates()
            insertRows(at: indexPaths, with: .bottom)
            endUpdates()
            CATransaction.commit()
        }
    }
    
    func insertMessagesAnimated(at indexPaths: [IndexPath], updateData: () -> Void, completion: @escaping (Bool) -> Void){
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                self?.insertRows(at: indexPaths, with: .bottom)
            }, completion: completion)
        } else {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                completion(true)
            }
            updateData()
            beginUpdates()
            insertRows(at: indexPaths, with: .bottom)
            endUpdates()
            CATransaction.commit()
        }
    }
}
