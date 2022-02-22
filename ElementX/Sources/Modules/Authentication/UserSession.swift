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
    case updatedData
}

enum UserSessionError: Error {
    case failedRetrievingAvatar
}

class UserSession: ClientDelegate {
    
    private let client: Client
    
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    
    init(client: Client) {
        self.client = client
        
        if !client.hasFirstSynced() {
            client.startSync(delegate: self)
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
    
    func getRoomList(_ completion: @escaping ([RoomModel]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let conversations = self.client.conversations()
            
            let rooms = conversations.map {
                return RoomModel(room: $0)
            }
            
            DispatchQueue.main.async {
                completion(rooms)
            }
        }
    }
    
    // MARK: ClientDelegate
    
    func didReceiveSyncUpdate() {
        DispatchQueue.main.async {
            self.callbacks.send(.updatedData)
        }
    }
}
