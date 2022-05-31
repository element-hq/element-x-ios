//
//  RoomProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//  Copyright © 2022 Element. All rights reserved.
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
        roomProxy?.appendMessage(message)
    }
}

class RoomProxy: RoomProxyProtocol {
    private let room: Room
    private let roomMessageFactory: RoomMessageFactoryProtocol
    
    private var backwardStream: BackwardsStreamProtocol?
    
    private(set) var displayName: String?
    
    let callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    private(set) var messages: [RoomMessageProtocol]
    
    init(room: Room, roomMessageFactory: RoomMessageFactoryProtocol) {
        self.room = room
        self.roomMessageFactory = roomMessageFactory
        messages = []
        
        room.setDelegate(delegate: WeakRoomProxyWrapper(roomProxy: self))
        
        backwardStream = room.startLiveEventListener()
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
        await Task.detached { () -> Result<String?, RoomProxyError> in
            do {
                let avatarURL = try self.room.memberAvatarUrl(userId: userId)
                return .success(avatarURL)
            } catch {
                return .failure(.failedRetrievingMemberAvatarURL)
            }
        }
        .value
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        await Task.detached { () -> Result<String?, RoomProxyError> in
            do {
                let displayName = try self.room.memberDisplayName(userId: userId)
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingMemberDisplayName)
            }
        }
        .value
    }
        
    func loadDisplayName() async -> Result<String, RoomProxyError> {
        await Task.detached { () -> Result<String, RoomProxyError> in
            if let displayName = self.displayName {
                return .success(displayName)
            }
            
            do {
                let displayName = try self.room.displayName()
                self.displayName = displayName
                
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
        .value
    }
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError> {
        await Task.detached { () -> Result<Void, RoomProxyError> in
            guard let backwardStream = self.backwardStream else {
                return .failure(RoomProxyError.backwardStreamNotAvailable)
            }

            Benchmark.startTrackingForIdentifier("BackPagination \(self.id)", message: "Backpaginating \(count) message(s) in room \(self.id)")
            let sdkMessages = backwardStream.paginateBackwards(count: UInt64(count))
            Benchmark.endTrackingForIdentifier("BackPagination \(self.id)", message: "Finished backpaginating \(count) message(s) in room \(self.id)")

            let messages = sdkMessages.map { message in
                self.roomMessageFactory.buildRoomMessageFrom(message)
            }.reversed()

            self.messages.insert(contentsOf: messages, at: 0)
            
            return .success(())
        }
        .value
    }
    
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        let messageContent = messageEventContentFromMarkdown(md: message)
        let transactionId = genTransactionId()
        
        return await Task(priority: .high) { () -> Result<Void, RoomProxyError> in
            do {
                try self.room.send(msg: messageContent, txnId: transactionId)
                return .success(())
            } catch {
                return .failure(.failedSendingMessage)
            }
        }
        .value
    }
    
    // MARK: - Private
    
    fileprivate func appendMessage(_ message: AnyMessage) {
        let message = roomMessageFactory.buildRoomMessageFrom(message)
        messages.append(message)
        callbacks.send(.updatedMessages)
    }
}
