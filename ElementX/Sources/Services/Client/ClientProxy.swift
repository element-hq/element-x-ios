//
//  ClientProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//  Copyright © 2022 Element. All rights reserved.
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
}

class ClientProxy: ClientProxyProtocol {
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
        
        Benchmark.startTrackingForIdentifier("ClientSync", message: "Started sync.")
        client.startSync()
        
        Task { await updateRooms() }
    }
    
    var userIdentifier: String {
        do {
            return try client.userId()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return "Unknown user identifier"
        }
    }
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        await Task.detached { () -> Result<String, ClientProxyError> in
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
        await Task.detached { () -> Result<String, ClientProxyError> in
            do {
                let avatarURL = try self.client.avatarUrl()
                return .success(avatarURL)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
        .value
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
    
    // MARK: Private
    
    fileprivate func didReceiveSyncUpdate() {
        Benchmark.logElapsedDurationForIdentifier("ClientSync", message: "Received sync update")
        
        callbacks.send(.receivedSyncUpdate)
        
        Task.detached {
            await self.updateRooms()
        }
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
