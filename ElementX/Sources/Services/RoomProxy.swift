//
//  RoomProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//

import Foundation
import UIKit
import Combine

import MatrixRustSDK

enum RoomProxyError: Error {
    case failedRetrievingDisplayName
    case failedRetrievingAvatar
    case backwardStreamNotAvailable
}

private class WeakRoomProxyWrapper: RoomDelegate {
    private weak var roomProxy: RoomProxy?
    
    init(roomProxy: RoomProxy) {
        self.roomProxy = roomProxy
    }
    
    // MARK: - RoomDelegate
    
    func didReceiveMessage(message: Message) {
        DispatchQueue.main.async {
            self.roomProxy?.appendMessage(message)
        }
    }
}

class RoomProxy: RoomProxyProtocol, Equatable {
    private let room: Room
    private let processingQueue: DispatchQueue
    
    private var backwardStream: BackwardsStreamProtocol?
    
    let callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    init(room: Room) {
        self.room = room
        processingQueue = DispatchQueue(label: "RoomProxyProcessingQueue")
        
        processingQueue.async {
            self.backwardStream = room.startLiveEventListener()
        }
        
        room.setDelegate(delegate: WeakRoomProxyWrapper(roomProxy: self))
    }
    
    var id: String {
        return room.id()
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
        
    var topic: String? {
        return room.topic()
    }
    
    var lastMessage: String? {
        didSet {
            callbacks.send(.updatedLastMessage)
        }
    }
    
    var avatarURL: URL? {
        guard let urlString = room.avatarUrl() else {
            return nil
        }
        
        return URL(string: urlString)
    }
    
    func loadDisplayName(_ completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let displayName = try self.room.displayName()
                
                DispatchQueue.main.async {
                    completion(.success(displayName))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RoomProxyError.failedRetrievingDisplayName))
                }
            }
        }
    }
    
    func loadAvatar(_ completion: @escaping (Result<UIImage?, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let avatarData = try self.room.avatar()
                
                DispatchQueue.main.async {
                    completion(.success(UIImage(data: Data(bytes: avatarData, count: avatarData.count))))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RoomProxyError.failedRetrievingAvatar))
                }
            }
        }
    }
        
    func paginateBackwards(count: UInt, callback: ((Result<[Message], Error>) -> Void)?) {
        processingQueue.async {
            guard let backwardStream = self.backwardStream else {
                DispatchQueue.main.async {
                    callback?(.failure(RoomProxyError.backwardStreamNotAvailable))
                }
                return
            }
            
            let messages = backwardStream.paginateBackwards(count: UInt64(count))
            
            DispatchQueue.main.async {                
                callback?(.success(messages))
                
                if self.lastMessage == nil {
                    self.lastMessage = messages.last?.content()
                }
            }
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: RoomProxy, rhs: RoomProxy) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Private
    
    fileprivate func preprendMessages(_ messages: [Message]) {
        
    }
    
    fileprivate func appendMessage(_ message: Message) {
        lastMessage = message.content()
        
        callbacks.send(.addedMessage(message))
    }
}
