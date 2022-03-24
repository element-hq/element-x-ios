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

private class WeakRoomProxyWrapper: RoomDelegate {
    private weak var roomProxy: RoomProxy?
    
    init(roomProxy: RoomProxy) {
        self.roomProxy = roomProxy
    }
    
    // MARK: - RoomDelegate
    
    func didReceiveMessage(message: AnyMessage) {
        DispatchQueue.main.async {
            self.roomProxy?.appendMessage(message)
        }
    }
}

class RoomProxy: RoomProxyProtocol, Equatable {
    private let room: Room
    private let messageFactory: RoomMessageFactory
    private let processingQueue: DispatchQueue
    
    private var backwardStream: BackwardsStreamProtocol?
    
    let callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    init(room: Room, messageFactory: RoomMessageFactory) {
        self.room = room
        self.messageFactory = messageFactory
        processingQueue = DispatchQueue(label: "RoomProxyProcessingQueue")
        
        processingQueue.async {
            self.backwardStream = room.startLiveEventListener()
        }
        
        room.setDelegate(delegate: WeakRoomProxyWrapper(roomProxy: self))
    }
    
    var id: String {
        room.id()
    }
    
    var name: String? {
        room.name()
    }
        
    var topic: String? {
        room.topic()
    }
    
    var isDirect: Bool {
        room.isDirect()
    }
    
    var isPublic: Bool {
        room.isPublic()
    }
    
    var isSpace: Bool {
        room.isSpace()
    }
    
    var isEncrypted: Bool {
        room.isEncrypted()
    }
    
    var isTombstoned: Bool {
        room.isTombstoned()
    }
    
    var lastMessage: String? {
        didSet {
            if lastMessage == oldValue {
                return
            }
            
            callbacks.send(.updatedLastMessage)
        }
    }
    
    var avatarURL: String? {
        room.avatarUrl()
    }
    
    func avatarURLForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void) {
        processingQueue.async {
            do {
                let avatarURL = try self.room.memberAvatarUrl(userId: userId)
                
                DispatchQueue.main.async {
                    completion(.success(avatarURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RoomProxyError.failedRetrievingMemberAvatarURL))
                }
            }
        }
    }
    
    func displayNameForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void) {
        processingQueue.async {
            do {
                let displayName = try self.room.memberDisplayName(userId: userId)
                
                DispatchQueue.main.async {
                    completion(.success(displayName))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RoomProxyError.failedRetrievingMemberDisplayName))
                }
            }
        }
    }
    
    func displayName(_ completion: @escaping (Result<String, RoomProxyError>) -> Void) {
        processingQueue.async {
            do {
                let displayName = try self.room.displayName()
                
                DispatchQueue.main.async {
                    completion(.success(displayName))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.failedRetrievingDisplayName))
                }
            }
        }
    }
            
    func paginateBackwards(count: UInt, callback: ((Result<[RoomMessageProtocol], RoomProxyError>) -> Void)?) {
        processingQueue.async {
            guard let backwardStream = self.backwardStream else {
                DispatchQueue.main.async {
                    callback?(.failure(.backwardStreamNotAvailable))
                }
                return
            }
            
            var messages = backwardStream.paginateBackwards(count: UInt64(count)).map { message in
                self.messageFactory.buildRoomMessageFrom(message)
            }
            
            // FIXME: Something wrong on the Rust side and these come in out of order sometimes.
            messages = messages.sorted(by: { $0.originServerTs < $1.originServerTs })
            
            DispatchQueue.main.async {                
                callback?(.success(messages))
                if self.lastMessage == nil {
                    self.lastMessage = messages.last?.body ?? ""
                }
            }
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: RoomProxy, rhs: RoomProxy) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Private
    
    fileprivate func appendMessage(_ message: AnyMessage) {
        let message = self.messageFactory.buildRoomMessageFrom(message)
        lastMessage = message.body
        
        callbacks.send(.addedMessage(message))
    }
}
