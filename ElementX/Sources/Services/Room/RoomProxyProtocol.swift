//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum RoomProxyError: Error {
    case sdkError(Error)
    
    case invalidURL
    case invalidMedia
    case eventNotFound
    case missingTransactionID
}

enum RoomProxyType {
    case joined(JoinedRoomProxyProtocol)
    case invited(InvitedRoomProxyProtocol)
    case knocked(KnockedRoomProxyProtocol)
    case left
    case banned
}

// sourcery: AutoMockable
protocol RoomProxyProtocol {
    var id: String { get }
    var ownUserID: String { get }
}

// sourcery: AutoMockable
protocol InvitedRoomProxyProtocol: RoomProxyProtocol {
    var info: BaseRoomInfoProxyProtocol { get }
    var inviter: RoomMemberProxyProtocol? { get }
    func rejectInvitation() async -> Result<Void, RoomProxyError>
}

// sourcery: AutoMockable
protocol KnockedRoomProxyProtocol: RoomProxyProtocol {
    var info: BaseRoomInfoProxyProtocol { get }
    func cancelKnock() async -> Result<Void, RoomProxyError>
}

enum JoinedRoomProxyAction: Equatable {
    case roomInfoUpdate
}

enum KnockRequestsState {
    case loading
    case loaded([KnockRequestProxyProtocol])
}

// sourcery: AutoMockable
protocol JoinedRoomProxyProtocol: RoomProxyProtocol {
    var isEncrypted: Bool { get }
    
    var infoPublisher: CurrentValuePublisher<RoomInfoProxy, Never> { get }

    var membersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> { get }
    
    var typingMembersPublisher: CurrentValuePublisher<[String], Never> { get }
    
    var identityStatusChangesPublisher: CurrentValuePublisher<[IdentityStatusChange], Never> { get }
    
    var knockRequestsStatePublisher: CurrentValuePublisher<KnockRequestsState, Never> { get }
    
    var timeline: TimelineProxyProtocol { get }
    
    var pinnedEventsTimeline: TimelineProxyProtocol? { get async }
    
    func subscribeForUpdates() async
    
    func subscribeToRoomInfoUpdates()
    
    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func messageFilteredTimeline(allowedMessageTypes: [RoomMessageEventMessageType]) async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func enableEncryption() async -> Result<Void, RoomProxyError>
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>
    
    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError>

    func leaveRoom() async -> Result<Void, RoomProxyError>
    
    func updateMembers() async

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError>
    
    func invite(userID: String) async -> Result<Void, RoomProxyError>
    
    func setName(_ name: String) async -> Result<Void, RoomProxyError>
    
    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError>
    
    func removeAvatar() async -> Result<Void, RoomProxyError>
    
    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError>
    
    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError>
    
    func edit(eventID: String, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError>
    
    /// https://spec.matrix.org/v1.9/client-server-api/#typing-notifications
    @discardableResult func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError>
    
    func ignoreDeviceTrustAndResend(devices: [String: [String]], sendHandle: SendHandleProxy) async -> Result<Void, RoomProxyError>
    
    func withdrawVerificationAndResend(userIDs: [String], sendHandle: SendHandleProxy) async -> Result<Void, RoomProxyError>
    
    // MARK: - Privacy settings
    
    func updateJoinRule(_ rule: JoinRule) async -> Result<Void, RoomProxyError>
    func updateHistoryVisibility(_ visibility: RoomHistoryVisibility) async -> Result<Void, RoomProxyError>
    
    func isVisibleInRoomDirectory() async -> Result<Bool, RoomProxyError>
    func updateRoomDirectoryVisibility(_ visibility: RoomVisibility) async -> Result<Void, RoomProxyError>
    
    // MARK: - Canonical Alias
    
    func updateCanonicalAlias(_ alias: String?, altAliases: [String]) async -> Result<Void, RoomProxyError>
    
    func publishRoomAliasInRoomDirectory(_ alias: String) async -> Result<Bool, RoomProxyError>
    func removeRoomAliasFromRoomDirectory(_ alias: String) async -> Result<Bool, RoomProxyError>
    
    // MARK: - Room Flags
    
    func flagAsUnread(_ isUnread: Bool) async -> Result<Void, RoomProxyError>
    
    func flagAsFavourite(_ isFavourite: Bool) async -> Result<Void, RoomProxyError>
    
    // MARK: - Power Levels
    
    func powerLevels() async -> Result<RoomPowerLevels, RoomProxyError>
    func applyPowerLevelChanges(_ changes: RoomPowerLevelChanges) async -> Result<Void, RoomProxyError>
    func resetPowerLevels() async -> Result<RoomPowerLevels, RoomProxyError>
    func suggestedRole(for userID: String) async -> Result<RoomMemberRole, RoomProxyError>
    func updatePowerLevelsForUsers(_ updates: [(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError>
    func canUser(userID: String, sendStateEvent event: StateEventType) async -> Result<Bool, RoomProxyError>
    func canUserInvite(userID: String) async -> Result<Bool, RoomProxyError>
    func canUserRedactOther(userID: String) async -> Result<Bool, RoomProxyError>
    func canUserRedactOwn(userID: String) async -> Result<Bool, RoomProxyError>
    func canUserKick(userID: String) async -> Result<Bool, RoomProxyError>
    func canUserBan(userID: String) async -> Result<Bool, RoomProxyError>
    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError>
    func canUserPinOrUnpin(userID: String) async -> Result<Bool, RoomProxyError>
    
    // MARK: - Moderation
    
    func kickUser(_ userID: String) async -> Result<Void, RoomProxyError>
    func banUser(_ userID: String) async -> Result<Void, RoomProxyError>
    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError>
    
    // MARK: - Element Call
    
    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError>
    func elementCallWidgetDriver(deviceID: String) -> ElementCallWidgetDriverProtocol
    
    func sendCallNotificationIfNeeded() async -> Result<Void, RoomProxyError>
    
    // MARK: - Permalinks
    
    func matrixToPermalink() async -> Result<URL, RoomProxyError>
    func matrixToEventPermalink(_ eventID: String) async -> Result<URL, RoomProxyError>
    
    // MARK: - Drafts
    
    func saveDraft(_ draft: ComposerDraft) async -> Result<Void, RoomProxyError>
    func loadDraft() async -> Result<ComposerDraft?, RoomProxyError>
    func clearDraft() async -> Result<Void, RoomProxyError>
}

extension JoinedRoomProxyProtocol {
    var details: RoomDetails {
        RoomDetails(id: id,
                    name: infoPublisher.value.displayName,
                    avatar: infoPublisher.value.avatar,
                    canonicalAlias: infoPublisher.value.canonicalAlias,
                    isEncrypted: isEncrypted,
                    isPublic: infoPublisher.value.isPublic)
    }
    
    var isDirectOneToOneRoom: Bool {
        infoPublisher.value.isDirect && infoPublisher.value.activeMembersCount <= 2
    }

    func members() async -> [RoomMemberProxyProtocol]? {
        await updateMembers()
        return membersPublisher.value
    }
}
