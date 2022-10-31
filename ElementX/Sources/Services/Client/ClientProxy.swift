//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import MatrixRustSDK
import UIKit

private class WeakClientProxyWrapper: ClientDelegate, SlidingSyncObserver {
    private weak var clientProxy: ClientProxy?
    
    init(clientProxy: ClientProxy) {
        self.clientProxy = clientProxy
    }
    
    // MARK: - ClientDelegate
    
    func didReceiveSyncUpdate() { }

    func didReceiveAuthError(isSoftLogout: Bool) {
        Task {
            await clientProxy?.didReceiveAuthError(isSoftLogout: isSoftLogout)
        }
    }

    func didUpdateRestoreToken() {
        Task {
            await clientProxy?.didUpdateRestoreToken()
        }
    }
    
    // MARK: - SlidingSyncDelegate
    
    func didReceiveSyncUpdate(summary: UpdateSummary) {
        Task {
            await self.clientProxy?.didReceiveSlidingSyncUpdate(summary: summary)
        }
    }
}

class ClientProxy: ClientProxyProtocol {
    /// The maximum number of timeline events required during a sync request.
    static let syncLimit: UInt16 = 50
    
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    private let mediaProxy: MediaProxyProtocol
    
    private var slidingSyncObserverToken: StoppableSpawn?
    private let slidingSync: SlidingSync
    
    let roomSummaryProvider: RoomSummaryProviderProtocol
    
    deinit {
        // These need to be inlined instead of using stopSync()
        // as we can't call async methods safely from deinit
        client.setDelegate(delegate: nil)
        slidingSyncObserverToken?.cancel()
        slidingSync.setObserver(observer: nil)
    }
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    init(client: ClientProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.client = client
        self.backgroundTaskService = backgroundTaskService
        mediaProxy = MediaProxy(client: client)
        
        do {
            let slidingSyncBuilder = try client.slidingSync().homeserver(url: BuildSettings.slidingSyncProxyBaseURL.absoluteString)
            
            let slidingSyncView = try SlidingSyncViewBuilder()
                .timelineLimit(limit: 10)
                .requiredState(requiredState: [RequiredState(key: "m.room.avatar", value: ""),
                                               RequiredState(key: "m.room.encryption", value: "")])
                .name(name: "HomeScreenView")
                .syncMode(mode: .fullSync)
                .build()
            
            slidingSync = try slidingSyncBuilder
                .addView(v: slidingSyncView)
                .withCommonExtensions()
                .build()
            
            roomSummaryProvider = RoomSummaryProvider(slidingSyncController: slidingSync,
                                                      slidingSyncView: slidingSyncView,
                                                      roomMessageFactory: RoomMessageFactory())
        } catch {
            fatalError("Failed configuring sliding sync")
        }
        
        client.setDelegate(delegate: WeakClientProxyWrapper(clientProxy: self))
    }
    
    var userIdentifier: String {
        do {
            return try client.userId()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return "Unknown user identifier"
        }
    }

    var isSoftLogout: Bool {
        client.isSoftLogout()
    }

    var deviceId: String? {
        do {
            return try client.deviceId()
        } catch {
            MXLog.error("Failed retrieving device id with error: \(error)")
            return nil
        }
    }

    var homeserver: String {
        client.homeserver()
    }

    var restoreToken: String? {
        do {
            return try client.restoreToken()
        } catch {
            MXLog.error("Failed retrieving restore token with error: \(error)")
            return nil
        }
    }
    
    func startSync() {
        guard !client.isSoftLogout() else {
            return
        }
        
        slidingSync.setObserver(observer: WeakClientProxyWrapper(clientProxy: self))
        slidingSyncObserverToken = slidingSync.sync()
    }
    
    func stopSync() {
        client.setDelegate(delegate: nil)
        
        slidingSyncObserverToken?.cancel()
        slidingSync.setObserver(observer: nil)
    }
    
    func roomForIdentifier(_ identifier: String) -> RoomProxyProtocol? {
        do {
            guard let slidingSyncRoom = try slidingSync.getRoom(roomId: identifier),
                  let room = slidingSyncRoom.fullRoom() else {
                MXLog.error("Failed retrieving room with identifier: \(identifier)")
                return nil
            }
            
            let roomProxy = RoomProxy(slidingSyncRoom: slidingSyncRoom,
                                      room: room,
                                      backgroundTaskService: backgroundTaskService)
            
            return roomProxy
        } catch {
            MXLog.error("Failed retrieving room with identifier: \(identifier)")
            return nil
        }
    }

    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                let displayName = try self.client.displayName()
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
    }
        
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                let avatarURL = try self.client.avatarUrl()
                return .success(avatarURL)
            } catch {
                return .failure(.failedRetrievingAvatarURL)
            }
        }
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedRetrievingAccountData)
    }
    
    func setAccountData<Content: Encodable>(content: Content, type: String) async -> Result<Void, ClientProxyError> {
        .failure(.failedSettingAccountData)
    }
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                let sessionVerificationController = try self.client.getSessionVerificationController()
                return .success(SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController))
            } catch {
                return .failure(.failedRetrievingSessionVerificationController)
            }
        }
    }

    func logout() async {
        do {
            try client.logout()
        } catch {
            MXLog.error("Failed logging out with error: \(error)")
        }
    }

    // swiftlint:disable:next function_parameter_count
    func setPusher(pushkey: String,
                   kind: PusherKind?,
                   appId: String,
                   appDisplayName: String,
                   deviceDisplayName: String,
                   profileTag: String?,
                   lang: String,
                   url: String?,
                   format: PushFormat?,
                   defaultPayload: [AnyHashable: Any]?) async throws {
        let defaultPayloadString = jsonString(from: defaultPayload)
        try await Task.dispatch(on: .global()) {
            try self.client.setPusher(pushkey: pushkey,
                                      kind: kind?.rustValue,
                                      appId: appId,
                                      appDisplayName: appDisplayName,
                                      deviceDisplayName: deviceDisplayName,
                                      profileTag: profileTag,
                                      lang: lang,
                                      url: url,
                                      format: format?.rustValue,
                                      defaultPayload: defaultPayloadString)
        }
    }
    
    // MARK: Private
    
    fileprivate func didReceiveAuthError(isSoftLogout: Bool) {
        callbacks.send(.receivedAuthError(isSoftLogout: isSoftLogout))
    }

    fileprivate func didUpdateRestoreToken() {
        callbacks.send(.updatedRestoreToken)
    }
    
    fileprivate func didReceiveSlidingSyncUpdate(summary: UpdateSummary) {
        roomSummaryProvider.updateRoomsWithIdentifiers(summary.rooms)
        
        callbacks.send(.receivedSyncUpdate)
    }

    /// Convenience method to get the json string of an Encodable
    private func jsonString(from dictionary: [AnyHashable: Any]?) -> String? {
        guard let dictionary,
              let data = try? JSONSerialization.data(withJSONObject: dictionary,
                                                     options: [.fragmentsAllowed]) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

extension ClientProxy: MediaProxyProtocol {
    func mediaSourceForURLString(_ urlString: String) -> MediaSourceProxy {
        mediaProxy.mediaSourceForURLString(urlString)
    }

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await mediaProxy.loadMediaContentForSource(source)
    }

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await mediaProxy.loadMediaThumbnailForSource(source, width: width, height: height)
    }
}
