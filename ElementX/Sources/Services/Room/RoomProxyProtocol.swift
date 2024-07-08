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
import MatrixRustSDK

enum RoomProxyError: Error {
    case sdkError(Error)
    
    case invalidURL
    case invalidMedia
    case eventNotFound
}

enum RoomProxyAction {
    case roomInfoUpdate
}

// sourcery: AutoMockable
protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var isFavourite: Bool { get async }
    var membership: Membership { get }
    var hasOngoingCall: Bool { get }
    var canonicalAlias: String? { get }
    var ownUserID: String { get }
    
    var name: String? { get }
    
    var topic: String? { get }
    
    /// The room's avatar info for use in a ``RoomAvatarImage``.
    var avatar: RoomAvatar { get }
    /// The room's avatar URL. Use this for editing and favour ``avatar`` for display.
    var avatarURL: URL? { get }

    var membersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> { get }
    
    var typingMembersPublisher: CurrentValuePublisher<[String], Never> { get }
    
    var joinedMembersCount: Int { get }
    
    var activeMembersCount: Int { get }
    
    var actionsPublisher: AnyPublisher<RoomProxyAction, Never> { get }
    
    var timeline: TimelineProxyProtocol { get }
    
    func subscribeForUpdates() async
    
    func unsubscribeFromUpdates() async
    
    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError>
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>
    
    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError>

    func leaveRoom() async -> Result<Void, RoomProxyError>
    
    func updateMembers() async

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError>
    
    func rejectInvitation() async -> Result<Void, RoomProxyError>
    
    func acceptInvitation() async -> Result<Void, RoomProxyError>
    
    func invite(userID: String) async -> Result<Void, RoomProxyError>
    
    func setName(_ name: String) async -> Result<Void, RoomProxyError>
    
    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError>
    
    func removeAvatar() async -> Result<Void, RoomProxyError>
    
    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError>
    
    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError>
    
    /// https://spec.matrix.org/v1.9/client-server-api/#typing-notifications
    @discardableResult func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError>
    
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
    
    // MARK: - Moderation
    
    func kickUser(_ userID: String) async -> Result<Void, RoomProxyError>
    func banUser(_ userID: String) async -> Result<Void, RoomProxyError>
    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError>
    
    // MARK: - Element Call
    
    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError>
    func elementCallWidgetDriver() -> ElementCallWidgetDriverProtocol
    
    func sendCallNotificationIfNeeeded() async -> Result<Void, RoomProxyError>
    
    // MARK: - Permalinks
    
    func matrixToPermalink() async -> Result<URL, RoomProxyError>
    func matrixToEventPermalink(_ eventID: String) async -> Result<URL, RoomProxyError>
    
    // MARK: - Drafts
    
    func saveDraft(_ draft: ComposerDraft) async -> Result<Void, RoomProxyError>
    func loadDraft() async -> Result<ComposerDraft?, RoomProxyError>
    func clearDraft() async -> Result<Void, RoomProxyError>
}

extension RoomProxyProtocol {
    var details: RoomDetails {
        RoomDetails(id: id,
                    name: name,
                    avatar: avatar,
                    canonicalAlias: canonicalAlias,
                    isEncrypted: isEncrypted,
                    isPublic: isPublic)
    }
        
    // Avoids to duplicate the same logic around in the app
    // Probably this should be done in rust.
    var roomTitle: String {
        name ?? "Unknown room 💥"
    }
    
    var isEncryptedOneToOneRoom: Bool {
        isDirect && isEncrypted && activeMembersCount <= 2
    }

    func members() async -> [RoomMemberProxyProtocol]? {
        await updateMembers()
        return membersPublisher.value
    }
}
