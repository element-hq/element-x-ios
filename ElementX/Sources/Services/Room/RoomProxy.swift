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
    private let room: Room
    private let roomMessageFactory: RoomMessageFactoryProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    private var sendMessageBgTask: BackgroundTaskProtocol?
    
    private(set) var displayName: String?
    
    private var backPaginationOutcome: PaginationOutcome?
    private(set) lazy var timelineProvider: RoomTimelineProviderProtocol = {
        let provider = RoomTimelineProvider(roomProxy: self)
        addTimelineListener(listener: WeakRoomTimelineProviderWrapper(timelineProvider: provider))
        return provider
    }()
    
    init(room: Room,
         roomMessageFactory: RoomMessageFactoryProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.room = room
        self.roomMessageFactory = roomMessageFactory
        self.backgroundTaskService = backgroundTaskService
    }
    
    deinit {
        #warning("Should any timeline listeners be removed??")
    }
    
    lazy var id: String = room.id()
    
    var name: String? {
        room.name()
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
                Benchmark.startTrackingForIdentifier("BackPagination \(self.id)", message: "Backpaginating \(count) message(s) in room \(self.id)")
                self.backPaginationOutcome = try self.room.paginateBackwards()
                Benchmark.endTrackingForIdentifier("BackPagination \(self.id)", message: "Finished backpaginating \(count) message(s) in room \(self.id)")
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
                // Disabled until available in Rust
                //                if let inReplyToEventId = inReplyToEventId {
                //                    #warning("Markdown support when available in Ruma")
                //                    try self.room.sendReply(msg: message, inReplyToEventId: inReplyToEventId, txnId: transactionId)
                //                } else {
                let messageContent = messageEventContentFromMarkdown(md: message)
                try self.room.send(msg: messageContent, txnId: transactionId)
                //                }
                return .success(())
            } catch {
                return .failure(.failedSendingMessage)
            }
        }
        .value
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        #warning("Redactions to be enabled on next SDK release.")
        return .failure(.failedRedactingEvent)
//        let transactionID = genTransactionId()
//
//        return await Task {
//            do {
//                try room.redact(eventId: eventID, reason: nil, txnId: transactionID)
//                return .success(())
//            } catch {
//                return .failure(.failedRedactingEvent)
//            }
//        }
//        .value
    }
}
