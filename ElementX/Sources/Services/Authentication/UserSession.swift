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
    private var rooms: [RoomProxy] = [] {
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
        client.startSync()
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
            MXLog.error("Failed retrieving room info with error: \(error)")
            return nil
        }
    }
    
    func getRoomList(_ completion: @escaping ([RoomProxyProtocol]) -> Void) {
        fetchRoomList(completion)
    }
    
    // MARK: ClientDelegate
    
    func didReceiveSyncUpdate() {
        fetchRoomList { [weak self] rooms in
            guard let self = self else { return }
            if self.rooms != rooms {
                self.rooms = rooms
            }
        }
        
        client.setDelegate(delegate: nil)
    }
    
    // MARK: Private
    
    func fetchRoomList(_ completion: @escaping ([RoomProxy]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let rooms = self.client.conversations().map {
                return RoomProxy(room: $0, messageFactory: RoomMessageFactory())
            }
            
            DispatchQueue.main.async {
                completion(rooms)
            }
        }
    }
}
