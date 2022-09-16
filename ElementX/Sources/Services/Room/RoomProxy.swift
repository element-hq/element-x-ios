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
    
    private var sendMessageBgTask: BackgroundTaskProtocol?
    
    private var memberAvatars = [String: String]()
    private var memberDisplayNames = [String: String]()
    
    private(set) var displayName: String?
    
    private var backPaginationOutcome: PaginationOutcome?
    private(set) lazy var timelineProvider: RoomTimelineProviderProtocol = {
        let provider = RoomTimelineProvider(roomProxy: self)
        addTimelineListener(listener: WeakRoomTimelineProviderWrapper(timelineProvider: provider))
        return provider
    }()
    
    deinit {
        #warning("Should any timeline listeners be removed??")
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
        room.isEncrypted()
    }
    
    var isTombstoned: Bool {
        room.isTombstoned()
    }
    
    var avatarURL: String? {
        room.avatarUrl()
    }

    var encryptionBadgeImage: UIImage? {
        guard isEncrypted else {
            return nil
        }

        //  return trusted image for now, should be updated after verification status known
        return Asset.Images.encryptionTrusted.image
    }
    
    func avatarURLStringForUserId(_ userId: String) -> String? {
        memberAvatars[userId]
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        await Task.detached { () -> Result<String?, RoomProxyError> in
            do {
                let avatarURL = try self.room.memberAvatarUrl(userId: userId)
                await self.update(avatarURL: avatarURL, forUserId: userId)
                return .success(avatarURL)
            } catch {
                return .failure(.failedRetrievingMemberAvatarURL)
            }
        }
        .value
    }
    
    func displayNameForUserId(_ userId: String) -> String? {
        memberDisplayNames[userId]
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        await Task.detached { () -> Result<String?, RoomProxyError> in
            do {
                let displayName = try self.room.memberDisplayName(userId: userId)
                await self.update(displayName: displayName, forUserId: userId)
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingMemberDisplayName)
            }
        }
        .value
    }
        
    func loadDisplayName() async -> Result<String, RoomProxyError> {
        await Task.detached { () -> Result<String, RoomProxyError> in
            if let displayName = await self.displayName {
                return .success(displayName)
            }
            
            do {
                let displayName = try self.room.displayName()
                await self.update(displayName: displayName)
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
        .value
    }
    
    private func addTimelineListener(listener: TimelineListener) {
        room.addTimelineListener(listener: listener)
    }
    
    #warning("The count parameter is unused.")
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError> {
        guard backPaginationOutcome?.moreMessages != false else {
            return .failure(.noMoreMessagesToBackPaginate)
        }

        return await Task.detached {
            do {
                let id = await self.id
                
                Benchmark.startTrackingForIdentifier("BackPagination \(id)", message: "Backpaginating \(count) message(s) in room \(id)")
                await self.update(backPaginationOutcome: try self.room.paginateBackwards())
                Benchmark.endTrackingForIdentifier("BackPagination \(id)", message: "Finished backpaginating \(count) message(s) in room \(id)")
                return .success(())
            } catch {
                return .failure(.failedPaginatingBackwards)
            }
        }
        .value
    }
    
    func sendMessage(_ message: String, inReplyToEventId: String? = nil) async -> Result<Void, RoomProxyError> {
        sendMessageBgTask = backgroundTaskService.startBackgroundTask(withName: "SendMessage", isReusable: true)
        defer {
            sendMessageBgTask?.stop()
        }
        
        let transactionId = genTransactionId()
        
        return await Task(priority: .high) { () -> Result<Void, RoomProxyError> in
            do {
                if let inReplyToEventId = inReplyToEventId {
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
        .value
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
    
    func update(avatarURL: String?, forUserId userId: String) {
        memberAvatars[userId] = avatarURL
    }
    
    func update(displayName: String?, forUserId userId: String) {
        memberDisplayNames[userId] = displayName
    }
    
    func update(displayName: String) {
        self.displayName = displayName
    }
    
    func update(backPaginationOutcome: PaginationOutcome) {
        self.backPaginationOutcome = backPaginationOutcome
    }
}
