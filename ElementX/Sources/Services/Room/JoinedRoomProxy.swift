//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import UIKit

class JoinedRoomProxy: JoinedRoomProxyProtocol {
    private let roomListService: RoomListServiceProtocol
    private let roomListItem: RoomListItemProtocol
    private let room: RoomProtocol
    let timeline: TimelineProxyProtocol
    
    private var innerPinnedEventsTimeline: TimelineProxyProtocol?
    private var innerPinnedEventsTimelineTask: Task<TimelineProxyProtocol?, Never>?
    var pinnedEventsTimeline: TimelineProxyProtocol? {
        get async {
            // Check if is already available.
            if let innerPinnedEventsTimeline {
                return innerPinnedEventsTimeline
                // Otherwise check if there is already a task loading it, and wait for it.
            } else if let innerPinnedEventsTimelineTask,
                      let value = await innerPinnedEventsTimelineTask.value {
                return value
                // Else create and store a new task to load it and wait for it.
            } else {
                let task = Task<TimelineProxyProtocol?, Never> { [weak self] in
                    guard let self else {
                        return nil
                    }
                    
                    do {
                        let timeline = try await TimelineProxy(timeline: room.pinnedEventsTimeline(internalIdPrefix: nil,
                                                                                                   maxEventsToLoad: 100,
                                                                                                   maxConcurrentRequests: 10),
                                                               kind: .pinned)
                        await timeline.subscribeForUpdates()
                        innerPinnedEventsTimeline = timeline
                        return timeline
                    } catch {
                        MXLog.error("Failed creating pinned events timeline with error: \(error)")
                        return nil
                    }
                }
                
                innerPinnedEventsTimelineTask = task
                return await task.value
            }
        }
    }
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var roomInfoObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var typingNotificationObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var identityStatusChangesObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var knockRequestsChangesObservationToken: TaskHandle?
    
    private var subscribedForUpdates = false
    
    private let infoSubject: CurrentValueSubject<RoomInfoProxy, Never>
    var infoPublisher: CurrentValuePublisher<RoomInfoProxy, Never> {
        infoSubject.asCurrentValuePublisher()
    }

    private let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
    var membersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> {
        membersSubject.asCurrentValuePublisher()
    }
    
    private let typingMembersSubject = CurrentValueSubject<[String], Never>([])
    var typingMembersPublisher: CurrentValuePublisher<[String], Never> {
        typingMembersSubject.asCurrentValuePublisher()
    }
    
    private let identityStatusChangesSubject = CurrentValueSubject<[IdentityStatusChange], Never>([])
    var identityStatusChangesPublisher: CurrentValuePublisher<[IdentityStatusChange], Never> {
        identityStatusChangesSubject.asCurrentValuePublisher()
    }
    
    private let knockRequestsStateSubject = CurrentValueSubject<KnockRequestsState, Never>(.loading)
    var knockRequestsStatePublisher: CurrentValuePublisher<KnockRequestsState, Never> {
        knockRequestsStateSubject.asCurrentValuePublisher()
    }
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = room.id()
    var ownUserID: String { room.ownUserId() }
    var info: RoomInfoProxy { infoSubject.value }
    
    var isEncrypted: Bool {
        (try? room.isEncrypted()) ?? false
    }
    
    init(roomListService: RoomListServiceProtocol,
         roomListItem: RoomListItemProtocol,
         room: RoomProtocol) async throws {
        self.roomListService = roomListService
        self.roomListItem = roomListItem
        self.room = room
        
        infoSubject = try await .init(RoomInfoProxy(roomInfo: room.roomInfo()))
        timeline = try await TimelineProxy(timeline: room.timeline(), kind: .live)
        
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

        do {
            try roomListService.subscribeToRooms(roomIds: [id])
        } catch {
            MXLog.error("Failed subscribing to room with error: \(error)")
        }
        
        await timeline.subscribeForUpdates()
        
        subscribeToRoomInfoUpdates()
        
        if isEncrypted {
            subscribeToIdentityStatusChanges()
        }
        
        subscribeToTypingNotifications()
        
        await subscribeToKnockRequests()
    }
    
    func subscribeToRoomInfoUpdates() {
        guard roomInfoObservationToken == nil else {
            return
        }
        
        roomInfoObservationToken = room.subscribeToRoomInfoUpdates(listener: RoomInfoUpdateListener { [weak self] roomInfo in
            MXLog.info("Received room info update")
            self?.infoSubject.send(.init(roomInfo: roomInfo))
        })
    }
    
    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        do {
            let timeline = try await room.timelineFocusedOnEvent(eventId: eventID, numContextEvents: numberOfEvents, internalIdPrefix: UUID().uuidString)
            return .success(TimelineProxy(timeline: timeline, kind: .detached))
        } catch let error as FocusEventError {
            switch error {
            case .InvalidEventId(_, let error):
                MXLog.error("Invalid event \(eventID) Error: \(error)")
                return .failure(.eventNotFound)
            case .EventNotFound:
                MXLog.error("Event \(eventID) not found.")
                return .failure(.eventNotFound)
            case .Other(let message):
                MXLog.error("Failed to create a timeline focussed on event \(eventID) Error: \(message)")
                return .failure(.sdkError(error))
            }
        } catch {
            MXLog.error("Unexpected error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func messageFilteredTimeline(allowedMessageTypes: [RoomMessageEventMessageType]) async -> Result<any TimelineProxyProtocol, RoomProxyError> {
        do {
            let timeline = try await TimelineProxy(timeline: room.messageFilteredTimeline(internalIdPrefix: nil,
                                                                                          allowedMessageTypes: allowedMessageTypes,
                                                                                          dateDividerMode: .monthly),
                                                   kind: .media(.mediaFilesScreen))
            await timeline.subscribeForUpdates()
            
            return .success(timeline)
        } catch {
            MXLog.error("Failed retrieving media events timeline with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        do {
            try await room.redact(eventId: eventID, reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed redacting eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        do {
            try await room.reportContent(eventId: eventID, score: nil, reason: reason)
            return .success(())
        } catch {
            MXLog.error("Failed reporting eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func updateMembers() async {
        // We always update members first using the no sync API in case internet is not readily available
        // To get the members stored on disk first, this API call is very fast.
        do {
            let membersNoSyncIterator = try await room.membersNoSync()
            if let members = membersNoSyncIterator.nextChunk(chunkSize: membersNoSyncIterator.len()) {
                membersSubject.value = members.map(RoomMemberProxy.init)
            }
        } catch {
            MXLog.error("[RoomProxy] Failed updating members using no sync API: \(error)")
        }
        
        do {
            // Then we update members using the sync API, this is slower but will get us the latest members
            let membersIterator = try await room.members()
            if let members = membersIterator.nextChunk(chunkSize: membersIterator.len()) {
                membersSubject.value = members.map(RoomMemberProxy.init)
            }
        } catch {
            MXLog.error("[RoomProxy] Failed updating members using sync API: \(error)")
        }
    }

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError> {
        if let member = membersPublisher.value.filter({ $0.userID == userID }).first {
            return .success(member)
        }
        
        do {
            let member = try await room.member(userId: userID)
            return .success(RoomMemberProxy(member: member))
        } catch {
            MXLog.error("Failed retrieving member \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func leaveRoom() async -> Result<Void, RoomProxyError> {
        do {
            try await room.leave()
            return .success(())
        } catch {
            MXLog.error("Failed leaving room with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func invite(userID: String) async -> Result<Void, RoomProxyError> {
        do {
            MXLog.info("Inviting user \(userID)")
            return try await .success(room.inviteUserById(userId: userID))
        } catch {
            MXLog.error("Failed inviting user \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func setName(_ name: String) async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.setName(name: name))
        } catch {
            MXLog.error("Failed setting name with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.setTopic(topic: topic))
        } catch {
            MXLog.error("Failed setting topic with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func removeAvatar() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.removeAvatar())
        } catch {
            MXLog.error("Failed removing avatar with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError> {
        guard case let .image(imageURL, _, _) = media, let mimeType = media.mimeType else {
            MXLog.error("Failed uploading avatar, invalid media: \(media)")
            return .failure(.invalidMedia)
        }

        do {
            let data = try Data(contentsOf: imageURL)
            return try await .success(room.uploadAvatar(mimeType: mimeType, data: data, mediaInfo: nil))
        } catch {
            MXLog.error("Failed uploading avatar with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
        
    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError> {
        do {
            try await room.markAsRead(receiptType: receiptType)
            return .success(())
        } catch {
            MXLog.error("Failed marking room \(id) as read with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func edit(eventID: String, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError> {
        do {
            try await room.edit(eventId: eventID, newContent: newContent)
            return .success(())
        } catch {
            MXLog.error("Failed editing event id \(eventID), in room \(id) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError> {
        do {
            try await room.typingNotice(isTyping: isTyping)
            return .success(())
        } catch {
            MXLog.error("Failed sending typing notice with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func ignoreDeviceTrustAndResend(devices: [String: [String]], sendHandle: SendHandleProxy) async -> Result<Void, RoomProxyError> {
        do {
            try await room.ignoreDeviceTrustAndResend(devices: devices, sendHandle: sendHandle.underlyingHandle)
            return .success(())
        } catch {
            MXLog.error("Failed trusting devices \(devices) and resending \(sendHandle.itemID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func withdrawVerificationAndResend(userIDs: [String], sendHandle: SendHandleProxy) async -> Result<Void, RoomProxyError> {
        do {
            try await room.withdrawVerificationAndResend(userIds: userIDs, sendHandle: sendHandle.underlyingHandle)
            return .success(())
        } catch {
            MXLog.error("Failed withdrawing verification of \(userIDs) and resending \(sendHandle.itemID) with error: \(error)")
            return .failure(.sdkError(error))
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
            return .failure(.sdkError(error))
        }
    }
    
    func flagAsFavourite(_ isFavourite: Bool) async -> Result<Void, RoomProxyError> {
        do {
            try await room.setIsFavourite(isFavourite: isFavourite, tagOrder: nil)
            return .success(())
        } catch {
            MXLog.error("Failed flagging room \(id) as favourite with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Power Levels
    
    func powerLevels() async -> Result<RoomPowerLevels, RoomProxyError> {
        do {
            return try await .success(room.getPowerLevels())
        } catch {
            MXLog.error("Failed building the current power level settings: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func applyPowerLevelChanges(_ changes: RoomPowerLevelChanges) async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.applyPowerLevelChanges(changes: changes))
        } catch {
            MXLog.error("Failed applying the power level changes: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func resetPowerLevels() async -> Result<RoomPowerLevels, RoomProxyError> {
        do {
            return try await .success(room.resetPowerLevels())
        } catch {
            MXLog.error("Failed resetting the power levels: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func suggestedRole(for userID: String) async -> Result<RoomMemberRole, RoomProxyError> {
        do {
            return try await .success(room.suggestedRoleForUser(userId: userID))
        } catch {
            MXLog.error("Failed getting a user's role: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func updatePowerLevelsForUsers(_ updates: [(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError> {
        do {
            let updates = updates.map { UserPowerLevelUpdate(userId: $0.userID, powerLevel: $0.powerLevel) }
            return try await .success(room.updatePowerLevelsForUsers(updates: updates))
        } catch {
            MXLog.error("Failed updating user power levels changes: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUser(userID: String, sendStateEvent event: StateEventType) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserSendState(userId: userID, stateEvent: event))
        } catch {
            MXLog.error("Failed checking if the user can send \(event) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserInvite(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserInvite(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can invite with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserRedactOther(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserRedactOther(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact others with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserRedactOwn(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserRedactOwn(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact self with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserKick(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserKick(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can kick with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserBan(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserBan(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can ban with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserTriggerRoomNotification(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserPinOrUnpin(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserPinUnpin(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can pin or unnpin: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Moderation
    
    func kickUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        do {
            try await room.kickUser(userId: userID, reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed kicking \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func banUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        do {
            try await room.banUser(userId: userID, reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed banning \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        do {
            try await room.unbanUser(userId: userID, reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed unbanning \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Element Call
    
    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserSendState(userId: userID, stateEvent: .callMember))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func elementCallWidgetDriver(deviceID: String) -> ElementCallWidgetDriverProtocol {
        ElementCallWidgetDriver(room: room, deviceID: deviceID)
    }
    
    func sendCallNotificationIfNeeded() async -> Result<Void, RoomProxyError> {
        do {
            try await room.sendCallNotificationIfNeeded()
            return .success(())
        } catch {
            MXLog.error("Failed room call notification with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Permalinks
    
    func matrixToPermalink() async -> Result<URL, RoomProxyError> {
        do {
            let urlString = try await room.matrixToPermalink()
            
            guard let url = URL(string: urlString) else {
                MXLog.error("Failed creating permalink for roomID: \(id), invalid permalink URL string: \(urlString)")
                return .failure(.invalidURL)
            }
            
            return .success(url)
        } catch {
            MXLog.error("Failed creating permalink for roomID: \(id) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func matrixToEventPermalink(_ eventID: String) async -> Result<URL, RoomProxyError> {
        do {
            let urlString = try await room.matrixToEventPermalink(eventId: eventID)
            
            guard let url = URL(string: urlString) else {
                MXLog.error("Failed creating permalink for eventID: \(eventID), invalid permalink URL string: \(urlString)")
                return .failure(.invalidURL)
            }
            
            return .success(url)
        } catch {
            MXLog.error("Failed creating permalink for eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Drafts
    
    func saveDraft(_ draft: ComposerDraft) async -> Result<Void, RoomProxyError> {
        do {
            try await room.saveComposerDraft(draft: draft)
            return .success(())
        } catch {
            MXLog.error("Failed saving draft with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func loadDraft() async -> Result<ComposerDraft?, RoomProxyError> {
        do {
            return try await .success(room.loadComposerDraft())
        } catch {
            MXLog.error("Failed restoring draft with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func clearDraft() async -> Result<Void, RoomProxyError> {
        do {
            try await room.clearComposerDraft()
            return .success(())
        } catch {
            MXLog.error("Failed clearing draft with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    // MARK: - Private
    
    private func subscribeToTypingNotifications() {
        typingNotificationObservationToken = room.subscribeToTypingNotifications(listener: RoomTypingNotificationUpdateListener { [weak self] typingUserIDs in
            guard let self else { return }
            
            MXLog.info("Received typing notification update, typingUsers: \(typingUserIDs)")
            
            let typingMembers = typingUserIDs.compactMap { userID in
                if let member = self.membersPublisher.value.filter({ $0.userID == userID }).first {
                    return member.displayName ?? member.userID
                } else {
                    return userID
                }
            }
            
            typingMembersSubject.send(typingMembers)
        })
    }
    
    private func subscribeToIdentityStatusChanges() {
        identityStatusChangesObservationToken = room.subscribeToIdentityStatusChanges(listener: RoomIdentityStatusChangeListener { [weak self] changes in
            guard let self else { return }
            
            MXLog.info("Received identity status changes: \(changes)")
            
            identityStatusChangesSubject.send(changes)
        })
    }
    
    private func subscribeToKnockRequests() async {
        do {
            knockRequestsChangesObservationToken = try await room.subscribeToKnockRequests(listener: RoomKnockRequestsListener { [weak self] requests in
                guard let self else { return }
                
                MXLog.info("Received requests to join update, requests id: \(requests.map(\.eventId))")
                knockRequestsStateSubject.send(.loaded(requests.map(KnockRequestProxy.init)))
            })
        } catch {
            MXLog.error("Failed observing requests to join with error: \(error)")
        }
    }
}

private final class RoomInfoUpdateListener: RoomInfoListener {
    private let onUpdateClosure: (RoomInfo) -> Void
    
    init(_ onUpdateClosure: @escaping (RoomInfo) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(roomInfo: RoomInfo) {
        onUpdateClosure(roomInfo)
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

private final class RoomIdentityStatusChangeListener: IdentityStatusChangeListener {
    private let onUpdateClosure: ([IdentityStatusChange]) -> Void
    
    init(_ onUpdateClosure: @escaping ([IdentityStatusChange]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(identityStatusChange: [IdentityStatusChange]) {
        onUpdateClosure(identityStatusChange)
    }
}

private final class RoomKnockRequestsListener: KnockRequestsListener {
    private let onUpdateClosure: ([KnockRequest]) -> Void
    
    init(_ onUpdateClosure: @escaping ([KnockRequest]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(joinRequests: [KnockRequest]) {
        onUpdateClosure(joinRequests)
    }
}
