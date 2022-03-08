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
}

private class WeakRoomProxyWrapper: RoomDelegate {
    private weak var roomProxy: RoomProxy?
    
    init(roomProxy: RoomProxy) {
        self.roomProxy = roomProxy
    }
    
    func didReceiveMessage(message: Message) {
        DispatchQueue.main.async {
            self.roomProxy?.appendMessage(message)
        }
    }
    
    func didPaginateBackwards(messages: [Message]) {
        DispatchQueue.main.async {
            self.roomProxy?.preprendMessages(messages)
        }
    }
}

class RoomProxy: RoomProxyProtocol, Equatable {
    private let room: Room
    
    let callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    init(room: Room) {
        self.room = room
        self.room.setDelegate(delegate: WeakRoomProxyWrapper(roomProxy: self))
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
    
    func startLiveEventListener() {
        room.startLiveEventListener()
    }
    
    func paginateBackwards(start: UInt, finish: UInt) {
        room.paginateBackwards(from: UInt8(start), to: UInt8(finish))
    }
    
    // MARK: - Equatable
    
    static func == (lhs: RoomProxy, rhs: RoomProxy) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Private
    
    fileprivate func preprendMessages(_ messages: [Message]) {
        if lastMessage == nil {
            lastMessage = messages.last?.content()
        }
        
        callbacks.send(.prependedMessages(messages))
    }
    
    fileprivate func appendMessage(_ message: Message) {
        lastMessage = message.content()
        
        callbacks.send(.addedMessage(message))
    }
}
