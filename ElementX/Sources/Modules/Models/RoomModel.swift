//
//  RoomModel.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//

import Foundation
import UIKit
import MatrixRustSDK

enum RoomModelError: Error {
    case failedRetrievingAvatar
}

struct RoomModel: RoomModelProtocol {
    
    private let room: Room
    
    init(room: Room) {
        self.room = room
    }
    
    var identifier: String {
        return room.identifier()
    }
    
    var isDirect: Bool {
        return room.isDirect()
    }
    
    var isPublic: Bool {
        return room.isPublic()
    }
    
    var isSpace: Bool {
        return room.isSpace()
    }
    
    var isEncrypted: Bool {
        return room.isEncrypted()
    }
    
    var name: String? {
        return room.name()
    }
    
    var displayName: String {
        do {
            return try room.displayName()
        } catch {
            MXLog.error("Failed retrieving room name with error: \(error)")
            return "Error"
        }
    }
    
    var topic: String? {
        return room.topic()
    }
    
    var lastMessage: String? {
        guard let lastMessage = try? room.messages().last else {
            return "Last message unknown"
        }
        
        return  "\(lastMessage.sender()): \(lastMessage.content())"
    }
    
    var avatarURL: URL? {
        guard let urlString = room.avatarUrl() else {
            return nil
        }
        
        return URL(string: urlString)
    }
    
    func loadAvatar(_ completion: @escaping (Result<UIImage?, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let avatarData = try room.avatar()
                
                DispatchQueue.main.async {
                    completion(.success(UIImage(data: Data(bytes: avatarData, count: avatarData.count))))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RoomModelError.failedRetrievingAvatar))
                }
            }
        }
    }
}
