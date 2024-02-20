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
    private let roomListItem: RoomListItemProtocol
    private let room: RoomProtocol
    let timeline: TimelineProxyProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private let backgroundTaskName = "SendRoomEvent"
    
    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.user_initiated", qos: .userInitiated)
    
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var roomInfoObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var typingNotificationObservationToken: TaskHandle?
    
    private var subscribedForUpdates = false
    
    private(set) var displayName: String?

    private let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
    var members: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> {
        membersSubject.asCurrentValuePublisher()
    }
    
    private let typingMembersSubject = CurrentValueSubject<[String], Never>([])
    var typingMembers: CurrentValuePublisher<[String], Never> {
        typingMembersSubject.asCurrentValuePublisher()
    }
        
    private let actionsSubject = PassthroughSubject<RoomProxyAction, Never>()
    var actions: AnyPublisher<RoomProxyAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    var ownUserID: String {
        room.ownUserId()
    }

    init?(roomListItem: RoomListItemProtocol,
          room: RoomProtocol,
          backgroundTaskService: BackgroundTaskServiceProtocol) async {
        self.roomListItem = roomListItem
        self.room = room
        self.backgroundTaskService = backgroundTaskService
        do {
            timeline = try await TimelineProxy(timeline: room.timeline(), backgroundTaskService: backgroundTaskService)
        } catch {
            MXLog.error("Failed creating timeline with error: \(error)")
            return nil
        }
        
        Task {
            await updateMembers()
        }
    }
    
    func subscribeForUpdates() async {
        guard !subscribedForUpdates else {
            MXLog.warning("Room already subscribed for updates")
            return
        }
        
        subscribedForUpdates = true
        let settings = RoomSubscription(requiredState: [RequiredState(key: "m.room.name", value: ""),
                                                        RequiredState(key: "m.room.topic", value: ""),
                                                        RequiredState(key: "m.room.avatar", value: ""),
                                                        RequiredState(key: "m.room.canonical_alias", value: ""),
                                                        RequiredState(key: "m.room.join_rules", value: "")],
                                        timelineLimit: UInt32(SlidingSyncConstants.defaultTimelineLimit))
        roomListItem.subscribe(settings: settings)
        
        await timeline.subscribeForUpdates()
        
        subscribeToRoomInfoUpdates()
        
        subscribeToTypingNotifications()
    }
    
    func unsubscribeFromUpdates() {
        roomListItem.unsubscribe()
    }

    lazy var id: String = room.id()
    
    var name: String? {
        roomListItem.name()
    }
        
    var topic: String? {
        room.topic()
    }
    
    var membership: Membership {
        room.membership()
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
    
    var isFavourite: Bool {
        get async {
            await (try? room.roomInfo().isFavourite) ?? false
        }
    }
    
    var hasOngoingCall: Bool {
        room.hasActiveRoomCall()
    }
    
    var canonicalAlias: String? {
        room.canonicalAlias()
    }
    
    var avatarURL: URL? {
        roomListItem.avatarUrl().flatMap(URL.init(string:))
    }

    var joinedMembersCount: Int {
        Int(room.joinedMembersCount())
    }
    
    var activeMembersCount: Int {
        Int(room.activeMembersCount())
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.redact(eventId: eventID, reason: nil)
                return .success(())
            } catch {
                return .failure(.failedRedactingEvent)
            }
        }
    }

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
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
        // We always update members first using the no sync API in case internet is not readily available
        // To get the members stored on disk first, this API call is very fast.
        do {
            let membersNoSyncIterator = try await room.membersNoSync()
            if let members = membersNoSyncIterator.nextChunk(chunkSize: membersNoSyncIterator.len()) {
                membersSubject.value = members.map {
                    RoomMemberProxy(member: $0, backgroundTaskService: self.backgroundTaskService)
                }
            }
        } catch {
            MXLog.error("[RoomProxy] Failed to update members using no sync API: \(error)")
        }
        
        do {
            // Then we update members using the sync API, this is slower but will get us the latest members
            let membersIterator = try await room.members()
            if let members = membersIterator.nextChunk(chunkSize: membersIterator.len()) {
                membersSubject.value = members.map {
                    RoomMemberProxy(member: $0, backgroundTaskService: self.backgroundTaskService)
                }
            }
        } catch {
            MXLog.error("[RoomProxy] Failed to update members using sync API: \(error)")
        }
    }

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError> {
        if let member = members.value.filter({ $0.userID == userID }).first {
            return .success(member)
        }
        
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        do {
            let member = try await room.member(userId: userID)
            return .success(RoomMemberProxy(member: member, backgroundTaskService: backgroundTaskService))
        } catch {
            return .failure(.failedRetrievingMember)
        }
    }
    
    func ignoreUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
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

    func leaveRoom() async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
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
    
    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.leave())
            } catch {
                return .failure(.failedRejectingInvite)
            }
        }
    }
    
    func acceptInvitation() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                try self.room.join()
                return .success(())
            } catch {
                return .failure(.failedAcceptingInvite)
            }
        }
    }
    
    func invite(userID: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                MXLog.info("Inviting user \(userID)")
                return try .success(self.room.inviteUserById(userId: userID))
            } catch {
                MXLog.error("Failed inviting user \(userID) with error: \(error)")
                return .failure(.failedInvitingUser)
            }
        }
    }
    
    func setName(_ name: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.setName(name: name))
            } catch {
                return .failure(.failedSettingRoomName)
            }
        }
    }

    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.setTopic(topic: topic))
            } catch {
                return .failure(.failedSettingRoomTopic)
            }
        }
    }
    
    func removeAvatar() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.removeAvatar())
            } catch {
                return .failure(.failedRemovingAvatar)
            }
        }
    }
    
    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            guard case let .image(imageURL, _, _) = media, let mimeType = media.mimeType else {
                return .failure(.failedUploadingAvatar)
            }

            do {
                let data = try Data(contentsOf: imageURL)
                return try .success(self.room.uploadAvatar(mimeType: mimeType, data: data, mediaInfo: nil))
            } catch {
                return .failure(.failedUploadingAvatar)
            }
        }
    }

    func canUserRedactOther(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserRedactOther(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact others with error: \(error)")
            return .failure(.failedCheckingPermission)
        }
    }
    
    func canUserRedactOwn(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserRedactOwn(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact self with error: \(error)")
            return .failure(.failedCheckingPermission)
        }
    }
    
    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserTriggerRoomNotification(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.failedCheckingPermission)
        }
    }
        
    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError> {
        do {
            try await room.markAsRead(receiptType: receiptType)
            return .success(())
        } catch {
            MXLog.error("Failed marking room \(id) as read with error: \(error)")
            return .failure(.failedMarkingAsRead)
        }
    }
    
    func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError> {
        MXLog.info("Sending typing notification isTyping: \(isTyping)")
        
        do {
            try await room.typingNotice(isTyping: isTyping)
            return .success(())
        } catch {
            MXLog.error("Failed sending typing notice with error: \(error)")
            return .failure(.failedSendingTypingNotice)
        }
    }
    
    // MARK: - Room flags
    
    func flagAsUnread(_ isUnread: Bool) async -> Result<Void, RoomProxyError> {
        MXLog.info("Flagging room \(id) as unread: \(isUnread)")
        
        do {
            try await room.setUnreadFlag(newValue: isUnread)
            return .success(())
        } catch {
            MXLog.error("Failed marking room \(id) as unread: \(isUnread) with error: \(error)")
            return .failure(.failedFlaggingAsUnread)
        }
    }
    
    func flagAsFavourite(_ isFavourite: Bool) async -> Result<Void, RoomProxyError> {
        do {
            try await room.setIsFavourite(isFavourite: isFavourite, tagOrder: nil)
            return .success(())
        } catch {
            MXLog.error("Failed flagging room \(id) as favourite with error: \(error)")
            return .failure(.failedFlaggingAsFavourite)
        }
    }
    
    // MARK: - Element Call
    
    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserSendState(userId: userID, stateEvent: .callMember))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.failedCheckingPermission)
        }
    }
    
    func elementCallWidgetDriver() -> ElementCallWidgetDriverProtocol {
        ElementCallWidgetDriver(room: room)
    }

    // MARK: - Private
    
    private func subscribeToRoomInfoUpdates() {
        roomInfoObservationToken = room.subscribeToRoomInfoUpdates(listener: RoomInfoUpdateListener { [weak self] in
            MXLog.info("Received room info update")
            self?.actionsSubject.send(.roomInfoUpdate)
        })
    }
    
    private func subscribeToTypingNotifications() {
        Task {
            typingNotificationObservationToken = await room.subscribeToTypingNotifications(listener: RoomTypingNotificationUpdateListener { [weak self] typingUserIDs in
                guard let self else { return }
                
                MXLog.info("Received typing notification update, typingUsers: \(typingUserIDs)")
                
                let typingMembers = typingUserIDs.compactMap { userID in
                    if let member = self.members.value.filter({ $0.userID == userID }).first {
                        return member.displayName ?? member.userID
                    } else {
                        return userID
                    }
                }
                
                typingMembersSubject.send(typingMembers)
            })
        }
    }
}

private final class RoomInfoUpdateListener: RoomInfoListener {
    private let onUpdateClosure: () -> Void
    
    init(_ onUpdateClosure: @escaping () -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(roomInfo: RoomInfo) {
        onUpdateClosure()
    }
}

private final class RoomTypingNotificationUpdateListener: TypingNotificationsListener {
    private let onUpdateClosure: ([String]) -> Void
    
    init(_ onUpdateClosure: @escaping ([String]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(typingUserIds: [String]) {
        onUpdateClosure(typingUserIds)
    }
}
