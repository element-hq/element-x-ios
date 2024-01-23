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

enum RoomProxyError: Error, Equatable {
    case failedRedactingEvent
    case failedReportingContent
    case failedRetrievingMember
    case failedLeavingRoom
    case failedAcceptingInvite
    case failedRejectingInvite
    case failedInvitingUser
    case failedSettingRoomName
    case failedSettingRoomTopic
    case failedRemovingAvatar
    case failedUploadingAvatar
    case failedCheckingPermission
}

enum RoomProxyAction {
    case stateUpdate
}

// sourcery: AutoMockable
protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var membership: Membership { get }
    var hasOngoingCall: Bool { get }
    var canonicalAlias: String? { get }
    var hasUnreadNotifications: Bool { get }
    var ownUserID: String { get }
    
    var name: String? { get }
    var displayName: String? { get }
    
    var topic: String? { get }
    
    var avatarURL: URL? { get }

    var members: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> { get }
        
    var joinedMembersCount: Int { get }
    
    var activeMembersCount: Int { get }
    
    var actions: AnyPublisher<RoomProxyAction, Never> { get }
    
    var timeline: TimelineProxyProtocol { get }
    
    func subscribeForUpdates() async
    
    func unsubscribeFromUpdates()
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>
    
    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError>
    
    func ignoreUser(_ userID: String) async -> Result<Void, RoomProxyError>

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

    func canUserRedactOther(userID: String) async -> Result<Bool, RoomProxyError>
    
    func canUserRedactOwn(userID: String) async -> Result<Bool, RoomProxyError>
    
    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError>
    
    func canUserJoinCall(userID: String) async -> Result<Bool, RoomProxyError>
    
    // MARK: - Element Call
    
    func elementCallWidgetDriver() -> ElementCallWidgetDriverProtocol
}

extension RoomProxyProtocol {
    var permalink: URL? {
        if let canonicalAlias, let link = try? PermalinkBuilder.permalinkTo(roomAlias: canonicalAlias,
                                                                            baseURL: ServiceLocator.shared.settings.permalinkBaseURL) {
            return link
        } else if let link = try? PermalinkBuilder.permalinkTo(roomIdentifier: id,
                                                               baseURL: ServiceLocator.shared.settings.permalinkBaseURL) {
            return link
        } else {
            MXLog.error("Failed to build permalink for Room: \(id)")
            return nil
        }
    }
    
    // Avoids to duplicate the same logic around in the app
    // Probably this should be done in rust.
    var roomTitle: String {
        displayName ?? name ?? "Unknown room 💥"
    }
    
    var isEncryptedOneToOneRoom: Bool {
        isDirect && isEncrypted && activeMembersCount <= 2
    }

    func members() async -> [RoomMemberProxyProtocol]? {
        await updateMembers()
        return members.value
    }
}
