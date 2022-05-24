//
//  UserSession.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//

import Foundation
import MatrixRustSDK
import Combine
import UIKit
import Kingfisher

enum UserSessionCallback {
    case updatedRoomsList
}

enum UserSessionError: Error {
    case failedRetrievingAvatarURL
    case failedRetrievingDisplayName
}

private class WeakUserSessionWrapper: ClientDelegate {
    private weak var userSession: UserSession?
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func didReceiveSyncUpdate() {
        self.userSession?.didReceiveSyncUpdate()
    }
}

class UserSession: ClientDelegate {
    
    private let client: Client
    
    private(set) var rooms: [RoomProxy] = [] {
        didSet {
            self.callbacks.send(.updatedRoomsList)
        }
    }
    
    let mediaProvider: MediaProviderProtocol
    
    deinit {
        client.setDelegate(delegate: nil)
    }
    
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    
    init(client: Client) {
        self.client = client
        self.mediaProvider = MediaProvider(client: client, imageCache: ImageCache.default)
        
        client.setDelegate(delegate: WeakUserSessionWrapper(userSession: self))
        
        Benchmark.startTrackingForIdentifier("ClientSync", message: "Started sync.")
        client.startSync()
        
        Task {
            await updateRooms()
        }
    }
    
    var userIdentifier: String {
        do {
            return try client.userId()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return "Unknown user identifier"
        }
    }
    
    func loadUserDisplayName() async -> Result<String, UserSessionError> {
        await withCheckedContinuation { continuation in
            do {
                let displayName = try self.client.displayName()
                continuation.resume(returning: .success(displayName))
            } catch {
                continuation.resume(returning: .failure(.failedRetrievingDisplayName))
            }
            
        }
    }
        
    func loadUserAvatarURL() async -> Result<String, UserSessionError> {
        await withCheckedContinuation { continuation in
            do {
                let avatarURL = try self.client.avatarUrl()
                continuation.resume(returning: .success(avatarURL))
            } catch {
                continuation.resume(returning: .failure(.failedRetrievingDisplayName))
            }
        }
    }
    
    // MARK: ClientDelegate
    
    func didReceiveSyncUpdate() {
        Benchmark.logElapsedDurationForIdentifier("ClientSync", message: "Received sync update")
        
        Task {
            await updateRooms()
        }
    }
    
    // MARK: Private
    
    private func updateRooms() async {
        var currentRooms = self.rooms
        Benchmark.startTrackingForIdentifier("ClientRooms", message: "Fetching available rooms")
        let sdkRooms = self.client.rooms()
        Benchmark.endTrackingForIdentifier("ClientRooms", message: "Retrieved \(sdkRooms.count) rooms")
        
        Benchmark.startTrackingForIdentifier("ProcessingRooms", message: "Started processing \(sdkRooms.count) rooms")
        let diff = sdkRooms.map({ $0.id()}).difference(from: currentRooms.map({ $0.id }))
        
        for change in diff {
            switch change {
            case .insert(_, let id, _):
                guard let sdkRoom = sdkRooms.first(where: { $0.id() == id }) else {
                    MXLog.error("Failed retrieving sdk room with id: \(id)")
                    break
                }
                currentRooms.append(RoomProxy(room: sdkRoom, messageFactory: RoomMessageFactory()))
            case .remove(_, let id, _):
                currentRooms.removeAll { $0.id == id }
            }
        }
        
        Benchmark.endTrackingForIdentifier("ProcessingRooms", message: "Finished processing \(sdkRooms.count) rooms")
        
        self.rooms = currentRooms
    }
}
