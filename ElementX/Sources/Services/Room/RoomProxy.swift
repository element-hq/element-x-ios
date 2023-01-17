//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import UIKit

import MatrixRustSDK

class RoomProxy: RoomProxyProtocol {
    private let slidingSyncRoom: SlidingSyncRoomProtocol
    private let room: RoomProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    private let serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.serial")
    
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    
    private var memberAvatars = [String: URL]()
    private var memberDisplayNames = [String: String]()
    
    private(set) var displayName: String?
    
    private var timelineObservationToken: StoppableSpawn?
    
    deinit {
        timelineObservationToken?.cancel()
    }
    
    init(slidingSyncRoom: SlidingSyncRoomProtocol,
         room: RoomProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.slidingSyncRoom = slidingSyncRoom
        self.room = room
        self.backgroundTaskService = backgroundTaskService
    }

    lazy var id: String = room.id()
    
    var name: String? {
        slidingSyncRoom.name()
    }
        
    var topic: String? {
        room.topic()
    }
    
    var isJoined: Bool {
        room.membership() == .joined
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
        (try? room.isEncrypted()) ?? false
    }
    
    var isTombstoned: Bool {
        room.isTombstoned()
    }
    
    var avatarURL: URL? {
        guard let urlString = room.avatarUrl() else {
            return nil
        }
        
        return URL(string: urlString)
    }

    var encryptionBadgeImage: UIImage? {
        guard isEncrypted else {
            return nil
        }

        //  return trusted image for now, should be updated after verification status known
        return Asset.Images.encryptionTrusted.image
    }
    
    func avatarURLForUserId(_ userId: String) -> URL? {
        memberAvatars[userId]
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError> {
        do {
            guard let urlString = try await Task.dispatch(on: serialDispatchQueue, {
                try self.room.memberAvatarUrl(userId: userId)
            }) else {
                return .success(nil)
            }
            
            guard let avatarURL = URL(string: urlString) else {
                MXLog.error("Invalid avatar URL string: \(String(describing: urlString))")
                return .failure(.failedRetrievingMemberAvatarURL)
            }
            
            update(url: avatarURL, forUserId: userId)
            return .success(avatarURL)
        } catch {
            return .failure(.failedRetrievingMemberAvatarURL)
        }
    }
    
    func displayNameForUserId(_ userId: String) -> String? {
        memberDisplayNames[userId]
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        do {
            let displayName = try await Task.dispatch(on: serialDispatchQueue) {
                try self.room.memberDisplayName(userId: userId)
            }
            update(displayName: displayName, forUserId: userId)
            return .success(displayName)
        } catch {
            return .failure(.failedRetrievingMemberDisplayName)
        }
    }
        
    func addTimelineListener(listener: TimelineListener) -> Result<Void, RoomProxyError> {
        if let token = slidingSyncRoom.addTimelineListener(listener: listener) {
            timelineObservationToken = token
            return .success(())
        } else {
            return .failure(.failedAddingTimelineListener)
        }
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError> {
        do {
            try await Task.dispatch(on: .global()) {
                try self.room.paginateBackwards(opts: .untilNumItems(eventLimit: UInt16(requestSize), items: UInt16(untilNumberOfItems)))
            }
            
            return .success(())
        } catch {
            return .failure(.failedPaginatingBackwards)
        }
    }
    
    func sendMessage(_ message: String, inReplyToEventId: String? = nil) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: "SendMessage", isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let transactionId = genTransactionId()
        
        return await Task.dispatch(on: .global()) {
            do {
                if let inReplyToEventId {
                    try self.room.sendReply(msg: message, inReplyToEventId: inReplyToEventId, txnId: transactionId)
                } else {
                    let messageContent = messageEventContentFromMarkdown(md: message)
                    try self.room.send(msg: messageContent, txnId: transactionId)
                }
                return .success(())
            } catch {
                return .failure(.failedSendingMessage)
            }
        }
    }
    
    func sendReaction(_ reaction: String, for eventId: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: "SendMessage", isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: .global()) {
            do {
                try self.room.sendReaction(eventId: eventId, key: reaction)
                return .success(())
            } catch {
                return .failure(.failedSendingReaction)
            }
        }
    }

    func editMessage(_ newMessage: String, originalEventId: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: "SendMessage", isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        let transactionId = genTransactionId()

        return await Task.dispatch(on: .global()) {
            do {
                try self.room.edit(newMsg: newMessage, originalEventId: originalEventId, txnId: transactionId)
                return .success(())
            } catch {
                return .failure(.failedEditingMessage)
            }
        }
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        let transactionID = genTransactionId()
        
        return await Task {
            do {
                try room.redact(eventId: eventID, reason: nil, txnId: transactionID)
                return .success(())
            } catch {
                return .failure(.failedRedactingEvent)
            }
        }
        .value
    }
    
    func members() async -> Result<[RoomMemberProxy], RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                let members = try self.room.members()
                return .success(members.map { RoomMemberProxy(with: $0) })
            } catch {
                return .failure(.failedRetrievingMembers)
            }
        }
    }
    
    func retryDecryption(forSessionId sessionId: String) async {
        await Task.dispatch(on: .global()) { [weak self] in
            self?.room.retryDecryption(sessionIds: [sessionId])
        }
    }
    
    // MARK: - Private
    
    private func update(url: URL?, forUserId userId: String) {
        memberAvatars[userId] = url
    }
    
    private func update(displayName: String?, forUserId userId: String) {
        memberDisplayNames[userId] = displayName
    }
    
    private func update(displayName: String) {
        self.displayName = displayName
    }
}
