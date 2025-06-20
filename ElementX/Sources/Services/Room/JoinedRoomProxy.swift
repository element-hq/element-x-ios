//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import UIKit

class JoinedRoomProxy: JoinedRoomProxyProtocol {
    private let roomListService: RoomListServiceProtocol
    private let room: RoomProtocol
    private let appSettings: AppSettings
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var roomInfoObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var typingNotificationObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var identityStatusChangesObservationToken: TaskHandle?
    // periphery:ignore - required for instance retention in the rust codebase
    private var knockRequestsChangesObservationToken: TaskHandle?
    
    private var innerPinnedEventsTimeline: TimelineProxyProtocol?
    private var innerPinnedEventsTimelineTask: Task<Result<TimelineProxyProtocol, RoomProxyError>, Never>?
    
    private var subscribedForUpdates = false
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = room.id()
    
    var ownUserID: String { room.ownUserId() }
    
    // The predecessor is set on room creation and never changes, so we lazily store it.
    lazy var predecessorRoom = room.predecessorRoom()
    
    // The successor may change over time, so we access it dynamically.
    // It's suggested to observe it through the `infoPublisher`
    var successorRoom: SuccessorRoom? {
        room.successorRoom()
    }
    
    let timeline: TimelineProxyProtocol
    
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
    
    init(roomListService: RoomListServiceProtocol,
         room: RoomProtocol,
         appSettings: AppSettings) async throws {
        self.roomListService = roomListService
        self.room = room
        self.appSettings = appSettings
        
        infoSubject = try await .init(RoomInfoProxy(roomInfo: room.roomInfo()))
        
        timeline = try await TimelineProxy(timeline: room.timelineWithConfiguration(configuration: .init(focus: .live(hideThreadedEvents: appSettings.threadsEnabled),
                                                                                                         filter: .eventTypeFilter(filter: excludedEventsFilter),
                                                                                                         internalIdPrefix: nil,
                                                                                                         dateDividerMode: .daily,
                                                                                                         trackReadReceipts: true,
                                                                                                         reportUtds: true)),
                                           kind: .live)
        
        Task {
            await updateMembers()
            
            // Try to update the encryption state if it's unknown.
            // This is an edge case as sliding sync should pass
            // that information down to the room info on the rust side.
            if room.encryptionState() == .unknown {
                MXLog.error("The encryption state should almost always be known.")
                _ = try? await room.latestEncryptionState()
            }
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
        
        Task {
            subscribeToRoomInfoUpdates()
            
            subscribeToTypingNotifications()
            
            await subscribeToKnockRequests()
            
            if infoPublisher.value.isEncrypted {
                await subscribeToIdentityStatusChanges()
            }
        }
    }
    
    func subscribeToRoomInfoUpdates() {
        guard roomInfoObservationToken == nil else {
            return
        }
        
        roomInfoObservationToken = room.subscribeToRoomInfoUpdates(listener: SDKListener { [weak self] roomInfo in
            MXLog.info("Received room info update")
            self?.infoSubject.send(.init(roomInfo: roomInfo))
        })
    }
    
    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        do {
            let sdkTimeline = try await room.timelineWithConfiguration(configuration: .init(focus: .event(eventId: eventID,
                                                                                                          numContextEvents: numberOfEvents,
                                                                                                          hideThreadedEvents: appSettings.threadsEnabled),
                                                                                            filter: .all,
                                                                                            internalIdPrefix: UUID().uuidString,
                                                                                            dateDividerMode: .daily,
                                                                                            trackReadReceipts: false,
                                                                                            reportUtds: true))
            
            return .success(TimelineProxy(timeline: sdkTimeline, kind: .detached))
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
    
    func threadTimeline(eventID: String) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        do {
            let sdkTimeline = try await room.timelineWithConfiguration(configuration: .init(focus: .thread(rootEventId: eventID, numEvents: 20),
                                                                                            filter: .all,
                                                                                            internalIdPrefix: UUID().uuidString,
                                                                                            dateDividerMode: .daily,
                                                                                            trackReadReceipts: true,
                                                                                            reportUtds: true))
            
            let timeline = TimelineProxy(timeline: sdkTimeline, kind: .thread(rootEventID: eventID))
            await timeline.subscribeForUpdates()
            
            return .success(timeline)
        } catch {
            MXLog.error("Unexpected error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func messageFilteredTimeline(focus: TimelineFocus,
                                 allowedMessageTypes: [TimelineAllowedMessageType],
                                 presentation: TimelineKind.MediaPresentation) async -> Result<any TimelineProxyProtocol, RoomProxyError> {
        do {
            let rustFocus: MatrixRustSDK.TimelineFocus = switch focus {
            case .live: .live(hideThreadedEvents: false)
            case .eventID(let eventID): .event(eventId: eventID, numContextEvents: 100, hideThreadedEvents: false)
            case .thread(let eventID): .thread(rootEventId: eventID, numEvents: 20)
            case .pinned: .pinnedEvents(maxEventsToLoad: 100, maxConcurrentRequests: 10)
            }
            
            let rustMessageTypes: [MatrixRustSDK.RoomMessageEventMessageType] = allowedMessageTypes.map {
                switch $0 {
                case .audio: .audio
                case .file: .file
                case .image: .image
                case .video: .video
                }
            }
            
            let sdkTimeline = try await room.timelineWithConfiguration(configuration: .init(focus: rustFocus,
                                                                                            filter: .onlyMessage(types: rustMessageTypes),
                                                                                            internalIdPrefix: nil,
                                                                                            dateDividerMode: .monthly,
                                                                                            trackReadReceipts: false,
                                                                                            reportUtds: true))
            
            let timeline = TimelineProxy(timeline: sdkTimeline, kind: .media(presentation))
            await timeline.subscribeForUpdates()
            
            return .success(timeline)
        } catch {
            MXLog.error("Failed retrieving media events timeline with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func pinnedEventsTimeline() async -> Result<TimelineProxyProtocol, RoomProxyError> {
        // Check if is already available.
        if let innerPinnedEventsTimeline {
            return .success(innerPinnedEventsTimeline)
            // Otherwise check if there is already a task loading it, and wait for it.
        } else if let innerPinnedEventsTimelineTask {
            return await innerPinnedEventsTimelineTask.value
        } else { // Else create and store a new task to load it and wait for it.
            let task = Task<Result<TimelineProxyProtocol, RoomProxyError>, Never> { [weak self] in
                guard let self else {
                    return .failure(.failedCreatingPinnedTimeline)
                }
                
                do {
                    let sdkTimeline = try await room.timelineWithConfiguration(configuration: .init(focus: .pinnedEvents(maxEventsToLoad: 100, maxConcurrentRequests: 10),
                                                                                                    filter: .all,
                                                                                                    internalIdPrefix: nil,
                                                                                                    dateDividerMode: .daily,
                                                                                                    trackReadReceipts: false,
                                                                                                    reportUtds: true))
                    
                    let timeline = TimelineProxy(timeline: sdkTimeline, kind: .pinned)
                    
                    await timeline.subscribeForUpdates()
                    innerPinnedEventsTimeline = timeline
                    return .success(timeline)
                } catch {
                    MXLog.error("Failed creating pinned events timeline with error: \(error)")
                    return .failure(.sdkError(error))
                }
            }
            
            innerPinnedEventsTimelineTask = task
            return await task.value
        }
    }
    
    func enableEncryption() async -> Result<Void, RoomProxyError> {
        do {
            try await room.enableEncryption()
            return .success(())
        } catch {
            MXLog.error("Failed enabling encryption with error: \(error)")
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
    
    func reportRoom(reason: String?) async -> Result<Void, RoomProxyError> {
        do {
            try await room.reportRoom(reason: reason)
            return .success(())
        } catch {
            MXLog.error("Failed reporting room: \(id) with error: \(error)")
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
    
    // MARK: - Privacy settings
    
    func updateJoinRule(_ rule: JoinRule) async -> Result<Void, RoomProxyError> {
        do {
            try await room.updateJoinRules(newRule: rule)
            return .success(())
        } catch {
            MXLog.error("Failed updating join rule with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func updateHistoryVisibility(_ visibility: RoomHistoryVisibility) async -> Result<Void, RoomProxyError> {
        do {
            try await room.updateHistoryVisibility(visibility: visibility)
            return .success(())
        } catch {
            MXLog.error("Failed updating history visibility with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func isVisibleInRoomDirectory() async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.getRoomVisibility() == .public)
        } catch {
            MXLog.error("Failed checking if room is visible in room directory with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func updateRoomDirectoryVisibility(_ visibility: RoomVisibility) async -> Result<Void, RoomProxyError> {
        do {
            try await room.updateRoomVisibility(visibility: visibility)
            return .success(())
        } catch {
            MXLog.error("Failed updating room directory visibility with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Canonical Alias
    
    func updateCanonicalAlias(_ alias: String?, altAliases: [String]) async -> Result<Void, RoomProxyError> {
        do {
            try await room.updateCanonicalAlias(alias: alias, altAliases: altAliases)
            return .success(())
        } catch {
            MXLog.error("Failed updating canonical alias with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func publishRoomAliasInRoomDirectory(_ alias: String) async -> Result<Bool, RoomProxyError> {
        do {
            let result = try await room.publishRoomAliasInRoomDirectory(alias: alias)
            return .success(result)
        } catch {
            MXLog.error("Failed publishing the room's alias in the room directory with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func removeRoomAliasFromRoomDirectory(_ alias: String) async -> Result<Bool, RoomProxyError> {
        do {
            let result = try await room.removeRoomAliasFromRoomDirectory(alias: alias)
            return .success(result)
        } catch {
            MXLog.error("Failed removing the room's alias in the room directory with error: \(error)")
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
    
    func powerLevels() async -> Result<RoomPowerLevelsProxyProtocol, RoomProxyError> {
        do {
            return try await .success(RoomPowerLevelsProxy(room.getPowerLevels()))
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
    
    func resetPowerLevels() async -> Result<Void, RoomProxyError> {
        do {
            _ = try await room.resetPowerLevels()
            return .success(())
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
    
    // MARK: - Moderation
    
    func kickUser(_ userID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        do {
            try await room.kickUser(userId: userID, reason: reason)
            return .success(())
        } catch {
            MXLog.error("Failed kicking \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func banUser(_ userID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        do {
            try await room.banUser(userId: userID, reason: reason)
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
    
    func elementCallWidgetDriver(deviceID: String) -> ElementCallWidgetDriverProtocol {
        ElementCallWidgetDriver(room: room, deviceID: deviceID)
    }
    
    func sendCallNotificationIfNeeded() async -> Result<Void, RoomProxyError> {
        do {
            _ = try await room.sendCallNotificationIfNeeded()
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
    
    func saveDraft(_ draft: ComposerDraft, threadRootEventID: String?) async -> Result<Void, RoomProxyError> {
        do {
            try await room.saveComposerDraft(draft: draft, threadRoot: threadRootEventID)
            return .success(())
        } catch {
            MXLog.error("Failed saving draft with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func loadDraft(threadRootEventID: String?) async -> Result<ComposerDraft?, RoomProxyError> {
        do {
            return try await .success(room.loadComposerDraft(threadRoot: threadRootEventID))
        } catch {
            MXLog.error("Failed restoring draft with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func clearDraft(threadRootEventID: String?) async -> Result<Void, RoomProxyError> {
        do {
            try await room.clearComposerDraft(threadRoot: threadRootEventID)
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
    
    private func subscribeToIdentityStatusChanges() async {
        do {
            identityStatusChangesObservationToken = try await room.subscribeToIdentityStatusChanges(listener: RoomIdentityStatusChangeListener { [weak self] changes in
                guard let self else { return }
                
                MXLog.info("Received identity status changes: \(changes)")
                
                identityStatusChangesSubject.send(changes)
            })
        } catch {
            MXLog.error("Failed subscribing to identity status changes with error: \(error)")
        }
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
    
    private let excludedEventsFilter: TimelineEventTypeFilter = {
        var stateEventFilters: [StateEventType] = [.roomAliases,
                                                   .roomCanonicalAlias,
                                                   .roomGuestAccess,
                                                   .roomHistoryVisibility,
                                                   .roomJoinRules,
                                                   .roomPinnedEvents,
                                                   .roomPowerLevels,
                                                   .roomServerAcl,
                                                   .roomTombstone,
                                                   .spaceChild,
                                                   .spaceParent,
                                                   .policyRuleRoom,
                                                   .policyRuleServer,
                                                   .policyRuleUser]
        return .exclude(eventTypes: stateEventFilters.map { FilterTimelineEventType.state(eventType: $0) })
    }()
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
