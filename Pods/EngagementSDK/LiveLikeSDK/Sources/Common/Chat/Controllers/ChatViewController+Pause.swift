//
//  ChatViewController+Pause.swift
//  EngagementSDK
//
//  Created by Jelzon Monzon on 7/22/19.
//

import Foundation

public extension ChatViewController {
    /**
     Pauses the ChatViewController.
     The user can no longer recieve or send messages until resume() is called.
     */
    @objc func pause() {
        guard let session = self.session as? InternalContentSession else {
            log.debug("Pause not necessary when session is nil.")
            return
        }

        session.pauseChat()
    }

    /**
     Resumes the ChatViewController.
     The user will load older messages from history and can send and receieve new messages.
     */
    @objc func resume() {
        guard let session = session as? InternalContentSession else {
            log.debug("Resume not necessary when session is nil.")
            return
        }
        session.resumeChat()
        
    }
}
