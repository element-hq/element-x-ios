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
        self.roomProxy?.appendMessage(message)
    }
}

class RoomProxy: RoomProxyProtocol {
    private let room: Room
    private let messageFactory: RoomMessageFactory
    
    private var backwardStream: BackwardsStreamProtocol?
    
    private(set) var displayName: String?
    
    let callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    private(set) var messages: [RoomMessageProtocol]
    
    init(room: Room, messageFactory: RoomMessageFactory) {
        self.room = room
        self.messageFactory = messageFactory
        messages = []
        
        room.setDelegate(delegate: WeakRoomProxyWrapper(roomProxy: self))
        
        Task {
            backwardStream = room.startLiveEventListener()
        }
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
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        await withCheckedContinuation({ continuation in
            do {
                let avatarURL = try self.room.memberAvatarUrl(userId: userId)
                continuation.resume(returning: .success(avatarURL))
            } catch {
                continuation.resume(returning: .failure(.failedRetrievingMemberAvatarURL))
            }
        })
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        await withCheckedContinuation({ continuation in
            do {
                let displayName = try self.room.memberDisplayName(userId: userId)
                continuation.resume(returning: .success(displayName))
            } catch {
                continuation.resume(returning: .failure(.failedRetrievingMemberDisplayName))
            }
        })
    }
        
    func loadDisplayName() async -> Result<String, RoomProxyError> {
        await withCheckedContinuation({ continuation in
            if let displayName = displayName {
                continuation.resume(returning: .success(displayName))
                return
            }
            
            do {
                let displayName = try self.room.displayName()
                self.displayName = displayName
                
                continuation.resume(returning: .success(displayName))
            } catch {
                continuation.resume(returning: .failure(.failedRetrievingDisplayName))
            }
        })
    }
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError> {
        await withCheckedContinuation { continuation in
            guard let backwardStream = self.backwardStream else {
                continuation.resume(returning: .failure(.backwardStreamNotAvailable))
                return
            }
            
            Benchmark.startTrackingForIdentifier("BackPagination \(self.id)", message: "Backpaginating \(count) message(s) in room \(self.id)")
            let sdkMessages = backwardStream.paginateBackwards(count: UInt64(count))
            Benchmark.endTrackingForIdentifier("BackPagination \(self.id)", message: "Finished backpaginating \(count) message(s) in room \(self.id)")
            
            let messages = sdkMessages.map { message in
                self.messageFactory.buildRoomMessageFrom(message)
            }.reversed()
            
            self.messages.insert(contentsOf: messages, at: 0)
            
            continuation.resume(returning: .success(()))
        }
    }
    
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        let messageContent = messageEventContentFromMarkdown(md: message)
        let transactionId = genTransactionId()
        
        return await withCheckedContinuation { continuation in
            do {
                try self.room.send(msg: messageContent, txnId: transactionId)
                continuation.resume(returning: .success(()))
            } catch {
                continuation.resume(returning: .failure(.failedSendingMessage))
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
