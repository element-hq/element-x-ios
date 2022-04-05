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

class RoomProxy: RoomProxyProtocol {
    private let room: Room
    private let messageFactory: RoomMessageFactory
    
    private let generalProcessingQueue: DispatchQueue
    private let messageProcessingQueue: DispatchQueue
    
    private var backwardStream: BackwardsStreamProtocol?
    
    let callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    private(set) var messages: [RoomMessageProtocol]
    
    init(room: Room, messageFactory: RoomMessageFactory) {
        self.room = room
        self.messageFactory = messageFactory
        generalProcessingQueue = DispatchQueue(label: "RoomProxyGeneralProcessingQueue")
        messageProcessingQueue = DispatchQueue(label: "RoomProxyMessageProcessingQueue")
        messages = []
        
        messageProcessingQueue.async {
            let backwardStream = room.startLiveEventListener()
            DispatchQueue.main.async {
                self.backwardStream = backwardStream
            }
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
    
    var avatarURL: String? {
        room.avatarUrl()
    }
    
    func avatarURLForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void) {
        generalProcessingQueue.async {
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
        generalProcessingQueue.async {
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
        generalProcessingQueue.async {
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
            
    func paginateBackwards(count: UInt, callback: ((Result<Void, RoomProxyError>) -> Void)?) {
        messageProcessingQueue.async {
            guard let backwardStream = self.backwardStream else {
                DispatchQueue.main.async {
                    callback?(.failure(.backwardStreamNotAvailable))
                }
                return
            }
            
            Benchmark.startTrackingForIdentifier("BackPagination \(self.id)", message: "Backpaginating \(count) message(s) in room \(self.id)")
            let sdkMessages = backwardStream.paginateBackwards(count: UInt64(count))
            Benchmark.endTrackingForIdentifier("BackPagination \(self.id)", message: "Finished backpaginating \(count) message(s) in room \(self.id)")
            
            let messages = sdkMessages.map { message in
                self.messageFactory.buildRoomMessageFrom(message)
            }.reversed()
            
            DispatchQueue.main.async {
                self.messages.insert(contentsOf: messages, at: 0)
                callback?(.success(()))
            }
        }
    }
    
    // MARK: - Private
    
    fileprivate func appendMessage(_ message: AnyMessage) {
        let message = self.messageFactory.buildRoomMessageFrom(message)
        messages.append(message)
        callbacks.send(.updatedMessages)
    }
}
