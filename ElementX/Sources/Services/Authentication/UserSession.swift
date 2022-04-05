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

private class WeakUserSessionWrapper: ClientDelegate {
    private weak var userSession: UserSession?
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func didReceiveSyncUpdate() {
        DispatchQueue.main.async {
            self.userSession?.didReceiveSyncUpdate()
        }
    }
}

class UserSession: ClientDelegate {
    
    private let client: Client
    private let processingQueue: DispatchQueue
    
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
        self.processingQueue = DispatchQueue(label: "UserSessionProcessingQueue")
        self.mediaProvider = MediaProvider(client: client, imageCache: ImageCache.default)
        
        client.setDelegate(delegate: WeakUserSessionWrapper(userSession: self))
        
        Benchmark.startTrackingForIdentifier("ClientSync", message: "Started sync.")
        client.startSync()
        
        updateRooms()
    }
    
    var userIdentifier: String {
        do {
            return try client.userId()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return "Unknown user identifier"
        }
    }
    
    var userDisplayName: String? {
        do {
            return try client.displayName()
        } catch {
            MXLog.error("Failed retrieving the user's display name with error: \(error)")
            return nil
        }
    }
    
    var userAvatarURL: String? {
        do {
            return try client.avatarUrl()
        } catch {
            MXLog.error("Failed retrieving the user's avatar URL with error: \(error)")
            return nil
        }
    }
    
    // MARK: ClientDelegate
    
    func didReceiveSyncUpdate() {
        Benchmark.logElapsedDurationForIdentifier("ClientSync", message: "Received sync update")
        updateRooms()
    }
    
    // MARK: Private
    
    func updateRooms() {
        var currentRooms = self.rooms
        self.processingQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
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
            
            DispatchQueue.main.async {
                self.rooms = currentRooms
            }
        }
    }
}
