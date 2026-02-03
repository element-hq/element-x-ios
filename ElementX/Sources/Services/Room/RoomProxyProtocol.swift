//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Algorithms
import Combine
import Foundation
import MatrixRustSDK

enum RoomProxyError: Error {
    case sdkError(Error)
    
    case invalidURL
    case invalidMedia
    case eventNotFound
    case missingTransactionID
    case failedCreatingPinnedTimeline
    case timelineError(TimelineProxyError)
}

/// An enum that describes the relationship between the current user and the room, and contains a reference to the specific implementation of the `RoomProxy`.
enum RoomProxyType {
    case joined(JoinedRoomProxyProtocol)
    case invited(InvitedRoomProxyProtocol)
    case knocked(KnockedRoomProxyProtocol)
    case banned(BannedRoomProxyProtocol)
    case left
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

// sourcery: AutoMockable
protocol BannedRoomProxyProtocol: RoomProxyProtocol {
    var info: BaseRoomInfoProxyProtocol { get }
    func forgetRoom() async -> Result<Void, RoomProxyError>
}

enum JoinedRoomProxyAction: Equatable {
    case roomInfoUpdate
}

enum KnockRequestsState {
    case loading
    case loaded([KnockRequestProxyProtocol])
}

struct RTCDeclinedEvent {
    /// The sender of the decline event
    let sender: String
    /// The rtc.notification event that is beeing declined
    let notificationEventID: String
}

// sourcery: AutoMockable
protocol JoinedRoomProxyProtocol: RoomProxyProtocol {
    var infoPublisher: CurrentValuePublisher<RoomInfoProxyProtocol, Never> { get }

    var membersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> { get }
    
    var typingMembersPublisher: CurrentValuePublisher<[String], Never> { get }
    
    var identityStatusChangesPublisher: CurrentValuePublisher<[IdentityStatusChange], Never> { get }
    
    var knockRequestsStatePublisher: CurrentValuePublisher<KnockRequestsState, Never> { get }
    
    var timeline: TimelineProxyProtocol { get }
    
    var predecessorRoom: PredecessorRoom? { get }
    
    var successorRoom: SuccessorRoom? { get }
    
    func subscribeForUpdates() async
    
    func subscribeToRoomInfoUpdates()
    
    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func threadTimeline(eventID: String) async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func loadOrFetchEventDetails(for eventID: String) async -> Result<TimelineEvent, RoomProxyError>
    
    func messageFilteredTimeline(focus: TimelineFocus,
                                 allowedMessageTypes: [TimelineAllowedMessageType],
                                 presentation: TimelineKind.MediaPresentation) async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func pinnedEventsTimeline() async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func enableEncryption() async -> Result<Void, RoomProxyError>
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>
    
    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError>
    
    func reportRoom(reason: String) async -> Result<Void, RoomProxyError>

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
    
    func powerLevels() async -> Result<RoomPowerLevelsProxyProtocol?, RoomProxyError>
    func applyPowerLevelChanges(_ changes: RoomPowerLevelChanges) async -> Result<Void, RoomProxyError>
    func resetPowerLevels() async -> Result<Void, RoomProxyError>
    func suggestedRole(for userID: String) async -> Result<RoomMemberRole, RoomProxyError>
    func updatePowerLevelsForUsers(_ updates: [(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError>
    
    // MARK: - Moderation
    
    func kickUser(_ userID: String, reason: String?) async -> Result<Void, RoomProxyError>
    func banUser(_ userID: String, reason: String?) async -> Result<Void, RoomProxyError>
    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError>
    
    // MARK: - Element Call
    
    func elementCallWidgetDriver(deviceID: String) -> ElementCallWidgetDriverProtocol
    func declineCall(notificationID: String) async -> Result<Void, RoomProxyError>
    func subscribeToCallDeclineEvents(rtcNotificationEventID: String, listener: CallDeclineListener) -> Result<TaskHandle, RoomProxyError>
    
    // MARK: - Permalinks
    
    func matrixToPermalink() async -> Result<URL, RoomProxyError>
    func matrixToEventPermalink(_ eventID: String) async -> Result<URL, RoomProxyError>
    
    // MARK: - Drafts
    
    func saveDraft(_ draft: ComposerDraft, threadRootEventID: String?) async -> Result<Void, RoomProxyError>
    func loadDraft(threadRootEventID: String?) async -> Result<ComposerDraft?, RoomProxyError>
    func clearDraft(threadRootEventID: String?) async -> Result<Void, RoomProxyError>
}

extension JoinedRoomProxyProtocol {
    var details: RoomDetails {
        let historySharingState: RoomHistorySharingState? = if infoPublisher.value.isEncrypted {
            infoPublisher.value.historySharingState
        } else {
            nil
        }
        
        return RoomDetails(id: id,
                           name: infoPublisher.value.displayName,
                           avatar: infoPublisher.value.avatar,
                           canonicalAlias: infoPublisher.value.canonicalAlias,
                           isEncrypted: infoPublisher.value.isEncrypted,
                           isPublic: !(infoPublisher.value.isPrivate ?? false),
                           isDirect: infoPublisher.value.isDirect,
                           historySharingState: historySharingState)
    }
    
    var isDirectOneToOneRoom: Bool {
        infoPublisher.value.isDirect && infoPublisher.value.activeMembersCount <= 2
    }

    func members() async -> [RoomMemberProxyProtocol]? {
        await updateMembers()
        return membersPublisher.value
    }
    
    /// This is a horrible workaround for not having any server names available when using tombstone links with v12 room IDs.
    func knownServerNames(maxCount: Int) -> any Sequence<String> {
        membersPublisher.value
            .prefix(1000) // No need to go crazy here…
            .compactMap { $0.userID.split(separator: ":").last.map(String.init) }
            .uniqued()
            .prefix(maxCount)
    }
}
