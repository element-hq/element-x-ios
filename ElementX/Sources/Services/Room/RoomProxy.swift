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
    private let backgroundTaskName = "SendRoomEvent"
    
    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.userinitiated", qos: .userInitiated)
    private let lowPriorityDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.lowpriority", qos: .utility)
    
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    
    private(set) var displayName: String?
    
    private var timelineObservationToken: TaskHandle?

    private let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
    var membersPublisher: AnyPublisher<[RoomMemberProxyProtocol], Never> {
        membersSubject.eraseToAnyPublisher()
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
    
    var canonicalAlias: String? {
        room.canonicalAlias()
    }
    
    var alternativeAliases: [String] {
        room.alternativeAliases()
    }
    
    var hasUnreadNotifications: Bool {
        slidingSyncRoom.hasUnreadNotifications()
    }
    
    var avatarURL: URL? {
        room.avatarUrl().flatMap(URL.init(string:))
    }

    var encryptionBadgeImage: UIImage? {
        guard isEncrypted else {
            return nil
        }

        //  return trusted image for now, should be updated after verification status known
        return Asset.Images.encryptionTrusted.image
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError> {
        do {
            guard let urlString = try await Task.dispatch(on: lowPriorityDispatchQueue, {
                try self.room.memberAvatarUrl(userId: userId)
            }) else {
                return .success(nil)
            }
            
            guard let avatarURL = URL(string: urlString) else {
                MXLog.error("Invalid avatar URL string: \(String(describing: urlString))")
                return .failure(.failedRetrievingMemberAvatarURL)
            }
            
            return .success(avatarURL)
        } catch {
            return .failure(.failedRetrievingMemberAvatarURL)
        }
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        do {
            let displayName = try await Task.dispatch(on: lowPriorityDispatchQueue) {
                try self.room.memberDisplayName(userId: userId)
            }
            return .success(displayName)
        } catch {
            return .failure(.failedRetrievingMemberDisplayName)
        }
    }
        
    func addTimelineListener(listener: TimelineListener) -> Result<[TimelineItem], RoomProxyError> {
        let settings = RoomSubscription(requiredState: [RequiredState(key: "m.room.topic", value: ""),
                                                        RequiredState(key: "m.room.canonical_alias", value: ""),
                                                        RequiredState(key: "m.room.join_rules", value: "")],
                                        timelineLimit: UInt32(SlidingSyncConstants.timelinePrecachingTimelineLimit))
        if let result = try? slidingSyncRoom.subscribeAndAddTimelineListener(listener: listener, settings: settings) {
            timelineObservationToken = result.taskHandle
            Task {
                await fetchMembers()
                await updateMembers()
            }
            return .success(result.items)
        } else {
            return .failure(.failedAddingTimelineListener)
        }
    }
    
    func removeTimelineListener() {
        timelineObservationToken?.cancel()
        timelineObservationToken = nil
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
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendReadReceipt(eventId: eventID)
                return .success(())
            } catch {
                return .failure(.failedSendingReadReceipt)
            }
        }
    }
    
    func sendMessage(_ message: String, inReplyTo eventID: String? = nil) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let transactionId = genTransactionId()
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                if let eventID {
                    try self.room.sendReply(msg: message, inReplyToEventId: eventID, txnId: transactionId)
                } else {
                    let messageContent = messageEventContentFromMarkdown(md: message)
                    self.room.send(msg: messageContent, txnId: transactionId)
                }
            } catch {
                return .failure(.failedSendingMessage)
            }
            return .success(())
        }
    }
    
    func sendReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendReaction(eventId: eventID, key: reaction)
                return .success(())
            } catch {
                return .failure(.failedSendingReaction)
            }
        }
    }
    
    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendImage(url: url.path(), thumbnailUrl: thumbnailURL.path(), imageInfo: imageInfo)
                return .success(())
            } catch {
                return .failure(.failedSendingMedia)
            }
        }
    }
    
    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendVideo(url: url.path(), thumbnailUrl: thumbnailURL.path(), videoInfo: videoInfo)
                return .success(())
            } catch {
                return .failure(.failedSendingMedia)
            }
        }
    }
    
    func sendAudio(url: URL, audioInfo: AudioInfo) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendAudio(url: url.path(), audioInfo: audioInfo)
                return .success(())
            } catch {
                return .failure(.failedSendingMedia)
            }
        }
    }
    
    func sendFile(url: URL, fileInfo: FileInfo) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendFile(url: url.path(), fileInfo: fileInfo)
                return .success(())
            } catch {
                return .failure(.failedSendingMedia)
            }
        }
    }

    func editMessage(_ newMessage: String, original eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        let transactionId = genTransactionId()

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.edit(newMsg: newMessage, originalEventId: eventID, txnId: transactionId)
                return .success(())
            } catch {
                return .failure(.failedEditingMessage)
            }
        }
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let transactionID = genTransactionId()
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.redact(eventId: eventID, reason: nil, txnId: transactionID)
                return .success(())
            } catch {
                return .failure(.failedRedactingEvent)
            }
        }
    }

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.reportContent(eventId: eventID, score: nil, reason: reason)
                return .success(())
            } catch {
                return .failure(.failedReportingContent)
            }
        }
    }

    func updateMembers() async {
        do {
            let roomMembers = try await Task.dispatch(on: .global()) {
                try self.room.members()
            }
            
            membersSubject.value = buildRoomMemberProxies(members: roomMembers)
        } catch {
            return
        }
    }
    
    func ignoreUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.ignoreUser(userId: userID)
                return .success(())
            } catch {
                return .failure(.failedReportingContent)
            }
        }
    }

    @MainActor
    private func buildRoomMemberProxies(members: [RoomMember]) -> [RoomMemberProxy] {
        members.map { RoomMemberProxy(member: $0, backgroundTaskService: backgroundTaskService) }
    }
    
    func retryDecryption(for sessionID: String) async {
        await Task.dispatch(on: .global()) { [weak self] in
            self?.room.retryDecryption(sessionIds: [sessionID])
        }
    }

    func leaveRoom() async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: .global()) {
            do {
                try self.room.leave()
                return .success(())
            } catch {
                MXLog.error("Failed to leave the room: \(error)")
                return .failure(.failedLeavingRoom)
            }
        }
    }
    
    func inviter() async -> RoomMemberProxyProtocol? {
        let inviter = await Task.dispatch(on: .global()) {
            self.room.inviter()
        }
        
        return inviter.map {
            RoomMemberProxy(member: $0, backgroundTaskService: self.backgroundTaskService)
        }
    }
    
    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.rejectInvitation())
            } catch {
                return .failure(.failedRejectingInvite)
            }
        }
    }
    
    func acceptInvitation() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.acceptInvitation())
            } catch {
                return .failure(.failedAcceptingInvite)
            }
        }
    }
    
    func fetchDetails(for eventID: String) {
        Task {
            await Task.dispatch(on: .global()) {
                do {
                    MXLog.info("Fetching event details for \(eventID)")
                    try self.room.fetchDetailsForEvent(eventId: eventID)
                } catch {
                    MXLog.error("Failed fetching event details for \(eventID) with error: \(error)")
                }
            }
        }
    }
    
    var invitedMembersCount: UInt64 {
        room.invitedMembersCount()
    }
    
    var joinedMembersCount: UInt64 {
        room.joinedMembersCount()
    }
    
    var activeMembersCount: UInt64 {
        room.activeMembersCount()
    }
    
    // MARK: - Private
    
    /// Force the timeline to load member details so it can populate sender profiles whenever we add a timeline listener
    /// This should become automatic on the RustSDK side at some point
    private func fetchMembers() async {
        await Task.dispatch(on: .global()) {
            self.room.fetchMembers()
        }
    }
        
    private func update(displayName: String) {
        self.displayName = displayName
    }
}
