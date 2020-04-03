//
//  ChatViewController+ProfileStatusBar.swift
//  EngagementSDK
//
//  Created by Jelzon WORK on 8/16/19.
//

import Foundation

extension ChatViewController {
    private func showProfileStatusBar() {
        profileStatusBar.isHidden = false
        profileStatusBarHeightConstraint?.constant = 24
    }

    private func hideProfileStatusBar() {
        profileStatusBar.isHidden = true
        profileStatusBarHeightConstraint?.constant = 0
    }

    func refreshProfileStatusBarVisibility() {
        if shouldDisplayProfileStatusBar, profileStatusBar.displayName.count > 0 {
            showProfileStatusBar()
        } else {
            hideProfileStatusBar()
        }
    }
}
