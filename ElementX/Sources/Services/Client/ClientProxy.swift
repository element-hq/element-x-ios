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
        clientProxy?.didReceiveAuthError(isSoftLogout: isSoftLogout)
    }

    func didUpdateRestoreToken() {
        clientProxy?.didUpdateRestoreToken()
    }
    
    // MARK: - SlidingSyncDelegate
    
    func didReceiveSyncUpdate(summary: UpdateSummary) {
        clientProxy?.didReceiveSlidingSyncUpdate(summary: summary)
    }
}

class ClientProxy: ClientProxyProtocol {
    /// The maximum number of timeline events required during a sync request.
    static let syncLimit: UInt16 = 50
    
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    private let clientQueue: DispatchQueue
    
    private var slidingSyncObserverToken: StoppableSpawn?
    private var slidingSync: SlidingSync!
    
    var roomSummaryProviderInternal: RoomSummaryProviderProtocol!
    var roomSummaryProvider: RoomSummaryProviderProtocol {
        guard let roomSummaryProviderInternal else {
            fatalError("There is an issue with ClientProxy object initialization")
        }
        return roomSummaryProviderInternal
    }
    
    deinit {
        // These need to be inlined instead of using stopSync()
        // as we can't call async methods safely from deinit
        client.setDelegate(delegate: nil)
        slidingSyncObserverToken?.cancel()
        slidingSync.setObserver(observer: nil)
    }
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    init(client: ClientProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol) async {
        self.client = client
        self.backgroundTaskService = backgroundTaskService
        clientQueue = .init(label: "ClientProxyQueue",
                            attributes: .concurrent)

        await Task.dispatch(on: clientQueue) {
            do {
                let slidingSyncBuilder = try client.slidingSync().homeserver(url: BuildSettings.slidingSyncProxyBaseURL.absoluteString)

                let slidingSyncView = try SlidingSyncViewBuilder()
                    .timelineLimit(limit: 10)
                    .requiredState(requiredState: [RequiredState(key: "m.room.avatar", value: ""),
                                                   RequiredState(key: "m.room.encryption", value: "")])
                    .name(name: "HomeScreenView")
                    .syncMode(mode: .fullSync)
                    .build()

                self.slidingSync = try slidingSyncBuilder
                    .addView(v: slidingSyncView)
                    .withCommonExtensions()
                    .build()

                self.roomSummaryProviderInternal = RoomSummaryProvider(slidingSyncController: self.slidingSync,
                                                                       slidingSyncView: slidingSyncView,
                                                                       roomMessageFactory: RoomMessageFactory())
            } catch {
                fatalError("Failed configuring sliding sync")
            }
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

    var restorationToken: RestorationToken? {
        do {
            return try RestorationToken(session: client.session())
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
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        let (slidingSyncRoom, room) = await Task.dispatch(on: clientQueue) {
            self.roomTupleForIdentifier(identifier)
        }

        guard let slidingSyncRoom, let room else {
            return nil
        }

        return await RoomProxy(slidingSyncRoom: slidingSyncRoom,
                               room: room,
                               backgroundTaskService: backgroundTaskService)
    }

    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let displayName = try self.client.displayName()
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
    }
        
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let avatarURL = try self.client.avatarUrl()
                return .success(avatarURL)
            } catch {
                return .failure(.failedRetrievingAvatarURL)
            }
        }
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        await Task.dispatch(on: clientQueue) {
            .failure(.failedRetrievingAccountData)
        }
    }
    
    func setAccountData<Content: Encodable>(content: Content, type: String) async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            .failure(.failedSettingAccountData)
        }
    }
    
    func mediaSourceForURLString(_ urlString: String) -> MatrixRustSDK.MediaSource {
        MatrixRustSDK.mediaSourceFromUrl(url: urlString)
    }
    
    func loadMediaContentForSource(_ source: MatrixRustSDK.MediaSource) async throws -> Data {
        try await Task.dispatch(on: clientQueue) {
            let bytes = try self.client.getMediaContent(source: source)
            return Data(bytes: bytes, count: bytes.count)
        }
    }
    
    func loadMediaThumbnailForSource(_ source: MatrixRustSDK.MediaSource, width: UInt, height: UInt) async throws -> Data {
        try await Task.dispatch(on: clientQueue) {
            let bytes = try self.client.getMediaThumbnail(source: source, width: UInt64(width), height: UInt64(height))
            return Data(bytes: bytes, count: bytes.count)
        }
    }
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let sessionVerificationController = try self.client.getSessionVerificationController()
                return .success(SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController))
            } catch {
                return .failure(.failedRetrievingSessionVerificationController)
            }
        }
    }

    func logout() async {
        await Task.dispatch(on: clientQueue) {
            do {
                try self.client.logout()
            } catch {
                MXLog.error("Failed logging out with error: \(error)")
            }
        }
    }
    
    // MARK: Private

    private func roomTupleForIdentifier(_ identifier: String) -> (SlidingSyncRoom?, Room?) {
        do {
            let slidingSyncRoom = try slidingSync.getRoom(roomId: identifier)
            let fullRoom = slidingSyncRoom?.fullRoom()

            return (slidingSyncRoom, fullRoom)
        } catch {
            MXLog.error("Failed retrieving room with identifier: \(identifier)")
            return (nil, nil)
        }
    }
    
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
}
