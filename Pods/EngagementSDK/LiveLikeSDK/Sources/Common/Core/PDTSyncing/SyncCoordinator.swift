//
//  SyncCoordinator.swift
//  EngagementSDK
//
//  Created by Cory Sullivan on 2019-04-15.
//

import Foundation

protocol SyncDelegate: AnyObject {
    func didReceivePin(_ pin: String, timeout: TimeInterval)
    func didReceiveError(_ error: Error)
    func didConnect()
}

protocol SyncMessagingClient {
    func subscribe(_ observer: SyncMessagingObserver, toChannel channel: String)
    func unSubcribe(_ observer: SyncMessagingObserver, fromChannel channel: String)
    func setPublishKey(_ publishKey: String, completion: @escaping () -> Void)
    func publish(message: String, channel: String)
}

protocol SyncMessagingObserver {
    func didReceiveSyncingEvent(_ event: SyncSessionStatus.Get)
    func didReceiveError(error: Error)
    func statusDidChange(status: ConnectionStatus)
}

enum SyncError: Error {
    case invalidChannel
    case invalidPublishKey
}

/// The `SyncCoordinator` is responsible for synchronizing video stream PDTs between the mobile app and CMS.
///
/// Currently the CMS is required to have the same video stream as the mobile apps playing in order to capture PDTs,
/// which is impractical in cases where LiveLike does not control the video stream.
/// This synchronization mechanism removes that requirement while maintaining accurate PDT sync.
/// https://quip.com/nMUSAaKJ9Rqw/PDT-sync-without-CMS-video-streams
class SyncCoordinator {
    // MARK: - Private

    private let syncSessionClient: SyncSessionClient
    private let syncMessagingClient: SyncMessagingClient
    private var syncChannel: String?
    private var timer: DispatchSourceTimer?
    private var playerTimeSource: PlayerTimeSource?
    private let syncSessionsUrl: URL
    private let userSessionId: String

    // MARK: - Internal

    weak var delegate: SyncDelegate?

    init(syncSessionClient: SyncSessionClient, syncMessagingClient: SyncMessagingClient, syncSessionsUrl: URL, userSessionId: String) {
        self.syncSessionClient = syncSessionClient
        self.syncMessagingClient = syncMessagingClient
        self.syncSessionsUrl = syncSessionsUrl
        self.userSessionId = userSessionId
    }

    deinit {
        timer?.cancel()
    }

    func startSyncingSession(playerTimeSource: PlayerTimeSource?) {
        self.playerTimeSource = playerTimeSource
        syncSessionClient.setSessionSync(url: syncSessionsUrl, userSessionId: userSessionId).then { syncSession in
            self.syncMessagingClient.subscribe(self, toChannel: syncSession.syncChannel)
            self.syncChannel = syncSession.syncChannel
            self.delegate?.didReceivePin(syncSession.pin, timeout: syncSession.connectTimeout)
        }.catch { error in
            self.delegate?.didReceiveError(error)
        }
    }

    func teardown() {
        if let syncChannel = syncChannel {
            syncMessagingClient.unSubcribe(self, fromChannel: syncChannel)
        }
    }
}

private extension SyncCoordinator {
    func startTimer() {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now(), repeating: .milliseconds(1000))
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            var programDateTime = Date()
            if let playerTimeSource = self.playerTimeSource?() {
                programDateTime = Date(timeIntervalSince1970: playerTimeSource)
            }
            let update = SyncSessionUpdate.Update(programDateTime: programDateTime)
            let syncUpdate = SyncSessionUpdate(event: .syncSessionUpdate, payload: update)
            self.publishEvent(syncUpdate)
        }
        timer?.resume()
    }

    func publishEvent<T: Any & Encodable>(_ event: T) {
        guard let channel = syncChannel else {
            DispatchQueue.main.async {
                self.delegate?.didReceiveError(SyncError.invalidChannel)
            }
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601Full)
            let json = try encoder.encode(event)
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let message = String(decoding: jsonData, as: UTF8.self)
            syncMessagingClient.publish(message: message, channel: channel)
        } catch {
            DispatchQueue.main.async {
                self.delegate?.didReceiveError(error)
            }
        }
    }
}

// MARK: - SyncMessagingObserver

extension SyncCoordinator: SyncMessagingObserver {
    func didReceiveSyncingEvent(_ event: SyncSessionStatus.Get) {
        switch event.status {
        case .ping:
            guard let publishKey = event.pubnubPublishKey else {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveError(SyncError.invalidPublishKey)
                }
                return
            }
            syncMessagingClient.setPublishKey(publishKey) { [weak self] in
                // expected format: {"event": "sync-session-status", "payload": {"status": "pong"}}
                guard let self = self else { return }
                let status = SyncSessionStatus.Payload(status: .pong)
                let statusEvent = SyncSessionStatus.Post(event: .syncSessionStatus, payload: status)
                self.publishEvent(statusEvent)
            }

        case .pong: break
        case .connected:
            DispatchQueue.main.async {
                self.delegate?.didConnect()
            }
            startTimer()
        }
    }

    func didReceiveError(error: Error) {
        DispatchQueue.main.async {
            self.delegate?.didReceiveError(error)
        }
    }

    func statusDidChange(status: ConnectionStatus) {
        log.verbose("Status did change \(status)")
    }
}
