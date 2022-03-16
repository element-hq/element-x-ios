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

enum UserSessionCallback {
    case updatedRoomsList
}

enum UserSessionError: Error {
    case failedRetrievingAvatar
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
    
    deinit {
        client.setDelegate(delegate: nil)
    }
    
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    
    init(client: Client) {
        self.client = client
        
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
    
    func loadUserAvatar(_ completion: @escaping (Result<UIImage?, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let avatarData = try self.client.avatar()
                DispatchQueue.main.async {
                    completion(.success(UIImage(data: Data(bytes: avatarData, count: avatarData.count))))
                }
            } catch {
                MXLog.error("Failed retrieving room name with error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(UserSessionError.failedRetrievingAvatar))
                }
            }
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
                return RoomProxy(room: $0)
            }
            
            DispatchQueue.main.async {
                completion(rooms)
            }
        }
    }
}
