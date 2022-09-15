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

private class WeakClientProxyWrapper: ClientDelegate {
    private weak var clientProxy: ClientProxy?
    
    init(clientProxy: ClientProxy) {
        self.clientProxy = clientProxy
    }
    
    func didReceiveSyncUpdate() {
        clientProxy?.didReceiveSyncUpdate()
    }

    func didReceiveAuthError(isSoftLogout: Bool) {
        clientProxy?.didReceiveAuthError(isSoftLogout: isSoftLogout)
    }

    func didUpdateRestoreToken() {
        clientProxy?.didUpdateRestoreToken()
    }
}

class ClientProxy: ClientProxyProtocol {
    /// The maximum number of timeline events required during a sync request.
    static let syncLimit: UInt16 = 20
    
    private let client: Client
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    
    private(set) var rooms: [RoomProxy] = [] {
        didSet {
            callbacks.send(.updatedRoomsList)
        }
    }
    
    deinit {
        client.setDelegate(delegate: nil)
    }
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    init(client: Client,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.client = client
        self.backgroundTaskService = backgroundTaskService
        
        client.setDelegate(delegate: WeakClientProxyWrapper(clientProxy: self))

        #warning("Use isSoftLogout() api on next SDK release.")
        Benchmark.startTrackingForIdentifier("ClientSync", message: "Started sync.")
        client.startSync(timelineLimit: ClientProxy.syncLimit)

        Task { await updateRooms() }
//        if !client.isSoftLogout() {
//            Benchmark.startTrackingForIdentifier("ClientSync", message: "Started sync.")
//            client.startSync(timelineLimit: ClientProxy.syncLimit)
//
//            Task { await updateRooms() }
//        }
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
        #warning("Use isSoftLogout() api on next SDK release.")
        return false
//        client.isSoftLogout()
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
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        await Task.detached {
            do {
                let displayName = try self.client.displayName()
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
        .value
    }
        
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError> {
        await Task.detached {
            do {
                let avatarURL = try self.client.avatarUrl()
                return .success(avatarURL)
            } catch {
                return .failure(.failedRetrievingAvatarURL)
            }
        }
        .value
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedRetrievingAccountData)
    }
    
    func setAccountData<Content: Encodable>(content: Content, type: String) async -> Result<Void, ClientProxyError> {
        .failure(.failedSettingAccountData)
    }
    
    func mediaSourceForURLString(_ urlString: String) -> MatrixRustSDK.MediaSource {
        MatrixRustSDK.mediaSourceFromUrl(url: urlString)
    }
    
    func loadMediaContentForSource(_ source: MatrixRustSDK.MediaSource) throws -> Data {
        let bytes = try client.getMediaContent(source: source)
        return Data(bytes: bytes, count: bytes.count)
    }
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        await Task.detached {
            do {
                let sessionVerificationController = try self.client.getSessionVerificationController()
                return .success(SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController))
            } catch {
                return .failure(.failedRetrievingSessionVerificationController)
            }
        }
        .value
    }

    func logout() async {
        do {
            #warning("Use logout() api on next SDK release.")
//            try client.logout()
        } catch {
            MXLog.error("Failed logging out with error: \(error)")
        }
    }
    
    // MARK: Private
    
    fileprivate func didReceiveSyncUpdate() {
        Benchmark.logElapsedDurationForIdentifier("ClientSync", message: "Received sync update")
        
        callbacks.send(.receivedSyncUpdate)
        
        Task.detached {
            await self.updateRooms()
        }
    }

    fileprivate func didReceiveAuthError(isSoftLogout: Bool) {
        callbacks.send(.receivedAuthError(isSoftLogout: isSoftLogout))
    }

    fileprivate func didUpdateRestoreToken() {
        callbacks.send(.updatedRestoreToken)
    }
    
    private func updateRooms() async {
        var currentRooms = rooms
        Benchmark.startTrackingForIdentifier("ClientRooms", message: "Fetching available rooms")
        let sdkRooms = client.rooms()
        Benchmark.endTrackingForIdentifier("ClientRooms", message: "Retrieved \(sdkRooms.count) rooms")
        
        Benchmark.startTrackingForIdentifier("ProcessingRooms", message: "Started processing \(sdkRooms.count) rooms")
        let diff = sdkRooms.map { $0.id() }.difference(from: currentRooms.map(\.id))
        
        for change in diff {
            switch change {
            case .insert(_, let id, _):
                guard let sdkRoom = sdkRooms.first(where: { $0.id() == id }) else {
                    MXLog.error("Failed retrieving sdk room with id: \(id)")
                    break
                }
                currentRooms.append(RoomProxy(room: sdkRoom,
                                              roomMessageFactory: RoomMessageFactory(),
                                              backgroundTaskService: backgroundTaskService))
            case .remove(_, let id, _):
                currentRooms.removeAll { $0.id == id }
            }
        }
        
        Benchmark.endTrackingForIdentifier("ProcessingRooms", message: "Finished processing \(sdkRooms.count) rooms")
        
        rooms = currentRooms
    }
}
