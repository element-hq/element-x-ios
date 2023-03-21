//
// Copyright 2023 New Vector Ltd
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

import MatrixRustSDK
import UIKit

struct RoomStateEventStringBuilder {
    let userID: String
    
    // swiftlint:disable:next cyclomatic_complexity
    func buildString(for change: MembershipChange?, member: String, sender: TimelineItemSender, isOutgoing: Bool) -> String? {
        guard let change else {
            MXLog.verbose("Filtering timeline item for membership change that is nil")
            return nil
        }
        
        let senderName = sender.displayName ?? sender.id
        let senderIsYou = isOutgoing
        let memberIsYou = member == userID
        
        switch change {
        case .joined:
            return memberIsYou ? L10n.stateEventRoomJoinByYou : L10n.stateEventRoomJoin(member)
        case .left:
            return memberIsYou ? L10n.stateEventRoomLeaveByYou : L10n.stateEventRoomLeave(member)
        case .banned, .kickedAndBanned:
            return senderIsYou ? L10n.stateEventRoomBanByYou(member) : L10n.stateEventRoomBan(senderName, member)
        case .unbanned:
            return senderIsYou ? L10n.stateEventRoomUnbanByYou(member) : L10n.stateEventRoomUnban(senderName, member)
        case .kicked:
            return senderIsYou ? L10n.stateEventRoomRemoveByYou(member) : L10n.stateEventRoomRemove(senderName, member)
        case .invited:
            if senderIsYou {
                return L10n.stateEventRoomInviteByYou(member)
            } else if memberIsYou {
                return L10n.stateEventRoomInviteYou(senderName)
            } else {
                return L10n.stateEventRoomInvite(senderName, member)
            }
        case .invitationAccepted:
            return memberIsYou ? L10n.stateEventRoomInviteAcceptedByYou : L10n.stateEventRoomInviteAccepted(member)
        case .invitationRejected:
            return memberIsYou ? L10n.stateEventRoomRejectByYou : L10n.stateEventRoomReject(member)
        case .invitationRevoked:
            return senderIsYou ? L10n.stateEventRoomThirdPartyRevokedInviteByYou(member) : L10n.stateEventRoomThirdPartyRevokedInvite(sender, member)
        case .knocked:
            return memberIsYou ? L10n.stateEventRoomKnockByYou : L10n.stateEventRoomKnock(member)
        case .knockAccepted:
            return senderIsYou ? L10n.stateEventRoomKnockAcceptedByYou(senderName) : L10n.stateEventRoomKnockAccepted(senderName, member)
        case .knockRetracted:
            return memberIsYou ? L10n.stateEventRoomKnockRetractedByYou : L10n.stateEventRoomKnockRetracted(member)
        case .knockDenied:
            if senderIsYou {
                return L10n.stateEventRoomKnockDeniedByYou(member)
            } else if memberIsYou {
                return L10n.stateEventRoomKnockDeniedYou(senderName)
            } else {
                return L10n.stateEventRoomKnockDenied(senderName, member)
            }
        case .none, .error, .notImplemented: // Not useful information for the user.
            MXLog.verbose("Filtering timeline item for membership change: \(change)")
            return nil
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    func buildProfileChangeString(displayName: String?, previousDisplayName: String?,
                                  avatarURLString: String?, previousAvatarURLString: String?,
                                  member: String, memberIsYou: Bool) -> String? {
        let displayNameChanged = displayName != previousDisplayName
        let avatarChanged = avatarURLString != previousAvatarURLString
        
        switch (displayNameChanged, avatarChanged, memberIsYou) {
        case (true, false, false):
            if let displayName, let previousDisplayName {
                return L10n.stateEventDisplayNameChangedFrom(member, previousDisplayName, displayName)
            } else if let displayName {
                return L10n.stateEventDisplayNameSet(member, displayName)
            } else if let previousDisplayName {
                return L10n.stateEventDisplayNameRemoved(member, previousDisplayName)
            } else {
                MXLog.error("The display name changed from nil to nil, filtering the item.")
                return nil
            }
        case (false, true, false):
            return L10n.stateEventAvatarUrlChanged(displayName ?? member)
        case (true, false, true):
            if let displayName, let previousDisplayName {
                return L10n.stateEventDisplayNameChangedFromByYou(previousDisplayName, displayName)
            } else if let displayName {
                return L10n.stateEventDisplayNameSetByYou(displayName)
            } else if let previousDisplayName {
                return L10n.stateEventDisplayNameRemovedByYou(previousDisplayName)
            } else {
                MXLog.error("The display name changed from nil to nil, filtering the item.")
                return nil
            }
        case (false, true, true):
            return L10n.stateEventAvatarUrlChangedByYou
        case (true, true, _):
            // When both have changed, get the string for the display name and tack on that the avatar changed too.
            guard let string = buildProfileChangeString(displayName: displayName, previousDisplayName: previousDisplayName,
                                                        avatarURLString: nil, previousAvatarURLString: nil,
                                                        member: member, memberIsYou: memberIsYou) else { return nil }
            return string + "\n" + L10n.stateEventAvatarChangedToo
        case (false, false, _):
            MXLog.error("Nothing changed, shouldn't be possible. Filtering the item.")
            return nil
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func buildString(for state: OtherState, stateKey: String?, sender: TimelineItemSender, isOutgoing: Bool) -> String? {
        let senderName = sender.displayName ?? sender.id
        
        switch state {
        case .roomAvatar(let url):
            switch (url, isOutgoing) {
            case (.some, false):
                return L10n.stateEventRoomAvatarChanged(senderName)
            case (nil, false):
                return L10n.stateEventRoomAvatarRemoved(senderName)
            case (.some, true):
                return L10n.stateEventRoomAvatarChangedByYou
            case (nil, true):
                return L10n.stateEventRoomAvatarRemovedByYou
            }
        case .roomCreate:
            return isOutgoing ? L10n.stateEventRoomCreatedByYou : L10n.stateEventRoomCreated(senderName)
        case .roomEncryption:
            return L10n.commonEncryptionEnabled
        case .roomName(let name):
            switch (name, isOutgoing) {
            case (.some(let name), false):
                return L10n.stateEventRoomNameChanged(senderName, name)
            case (nil, false):
                return L10n.stateEventRoomNameRemoved(senderName)
            case (.some(let name), true):
                return L10n.stateEventRoomNameChangedByYou(name)
            case (nil, true):
                return L10n.stateEventRoomNameRemovedByYou
            }
        case .roomThirdPartyInvite(let displayName):
            guard let displayName else {
                MXLog.error("roomThirdPartyInvite undisplayable due to missing name.")
                return nil
            }
            
            if isOutgoing {
                return L10n.stateEventRoomThirdPartyInviteByYou(displayName)
            } else {
                return L10n.stateEventRoomThirdPartyInvite(senderName, displayName)
            }
        case .roomTopic(let topic):
            switch (topic, isOutgoing) {
            case (.some(let topic), false):
                return L10n.stateEventRoomTopicChanged(senderName, topic)
            case (nil, false):
                return L10n.stateEventRoomTopicRemoved(senderName)
            case (.some(let name), true):
                return L10n.stateEventRoomTopicChangedByYou(name)
            case (nil, true):
                return L10n.stateEventRoomTopicRemovedByYou
            }
        case .policyRuleRoom, .policyRuleServer, .policyRuleUser: // No strings available.
            break
        case .roomAliases, .roomCanonicalAlias: // Doesn't provide the alias.
            break
        case .roomGuestAccess, .roomHistoryVisibility: // Doesn't provide information about the change.
            break
        case .roomJoinRules: // Doesn't provide information about the change.
            break
        case .roomPinnedEvents, .roomPowerLevels, .roomServerAcl: // Doesn't provide information about the change.
            break
        case .roomTombstone: // Handle as a virtual timeline item with a link to the upgraded room.
            break
        case .spaceChild, .spaceParent: // Users shouldn't see the timeline of a Space.
            break
        case .custom: // Won't provide actionable information to the user.
            break
        }
        
        MXLog.verbose("Filtering timeline item for state: \(state)")
        return nil
    }
}
