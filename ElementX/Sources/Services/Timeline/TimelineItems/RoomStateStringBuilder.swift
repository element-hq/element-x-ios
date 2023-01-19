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

struct RoomStateStringBuilder {
    let userID: String
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func buildString(for change: MembershipChange, member: String, sender: TimelineItemSender, isOutgoing: Bool) -> String? {
        let senderName = sender.displayName ?? sender.id
        let senderIsYou = isOutgoing
        let memberIsYou = member == userID
        
        switch change {
        case .joined:
            return memberIsYou ? ElementL10n.noticeRoomJoinByYou : ElementL10n.noticeRoomJoin(member)
        case .left:
            return memberIsYou ? ElementL10n.noticeRoomLeaveByYou : ElementL10n.noticeRoomLeave(member)
        case .banned, .kickedAndBanned:
            return senderIsYou ? ElementL10n.noticeRoomBanByYou(member) : ElementL10n.noticeRoomBan(senderName, member)
        case .unbanned:
            return senderIsYou ? ElementL10n.noticeRoomUnbanByYou(member) : ElementL10n.noticeRoomUnban(senderName, member)
        case .kicked:
            return senderIsYou ? ElementL10n.noticeRoomRemoveByYou(member) : ElementL10n.noticeRoomRemove(senderName, member)
        case .invited:
            if senderIsYou {
                return ElementL10n.noticeRoomInviteByYou(member)
            } else if memberIsYou {
                return ElementL10n.noticeRoomInviteYou(senderName)
            } else {
                return ElementL10n.noticeRoomInvite(senderName, member)
            }
        case .invitationAccepted:
            return memberIsYou ? ElementL10n.noticeRoomInviteAcceptedByYou : ElementL10n.noticeRoomInviteAccepted(member)
        case .invitationRejected:
            return memberIsYou ? ElementL10n.noticeRoomRejectByYou : ElementL10n.noticeRoomReject(member)
        case .invitationRevoked:
            return senderIsYou ? ElementL10n.noticeRoomThirdPartyRevokedInviteByYou(member) : ElementL10n.noticeRoomThirdPartyRevokedInvite(sender, member)
        case .knocked:
            return memberIsYou ? ElementL10n.noticeRoomKnockByYou : ElementL10n.noticeRoomKnock(member)
        case .knockAccepted:
            return senderIsYou ? ElementL10n.noticeRoomKnockAcceptedByYou(senderName) : ElementL10n.noticeRoomKnockAccepted(senderName, member)
        case .knockRetracted:
            return memberIsYou ? ElementL10n.noticeRoomKnockRetractedByYou : ElementL10n.noticeRoomKnockRetracted(member)
        case .knockDenied:
            if senderIsYou {
                return ElementL10n.noticeRoomKnockDeniedByYou(member)
            } else if memberIsYou {
                return ElementL10n.noticeRoomKnockDeniedYou(senderName)
            } else {
                return ElementL10n.noticeRoomKnockDenied(senderName, member)
            }
        case .profileChanged(let displayName, let previousDisplayName, let avatarURLString, let previousAvatarURLString):
            return profileChangedString(displayName: displayName, previousDisplayName: previousDisplayName,
                                        avatarURLString: avatarURLString, previousAvatarURLString: previousAvatarURLString,
                                        member: member, memberIsYou: memberIsYou,
                                        sender: sender, senderIsYou: senderIsYou)
        case .none, .error, .notImplemented, .unknown: // Not useful information for the user.
            MXLog.verbose("Filtering timeline item for membership change: \(change)")
            return nil
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    private func profileChangedString(displayName: String?, previousDisplayName: String?,
                                      avatarURLString: String?, previousAvatarURLString: String?,
                                      member: String, memberIsYou: Bool,
                                      sender: TimelineItemSender, senderIsYou: Bool) -> String {
        let displayNameChanged = displayName != previousDisplayName
        let avatarChanged = avatarURLString != previousAvatarURLString
        
        switch (displayNameChanged, avatarChanged, memberIsYou) {
        case (true, false, false):
            if let displayName, let previousDisplayName {
                return ElementL10n.noticeDisplayNameChangedFrom(member, displayName, previousDisplayName)
            } else if let displayName {
                return ElementL10n.noticeDisplayNameSet(member, displayName)
            } else if let previousDisplayName {
                return ElementL10n.noticeDisplayNameRemoved(member, previousDisplayName)
            } else {
                MXLog.error("The display name changed from nil to nil, shouldn't be possible.")
                return ElementL10n.noticeMemberNoChanges(member)
            }
        case (false, true, false):
            return ElementL10n.noticeAvatarUrlChanged(displayName ?? member)
        case (true, true, false):
            return profileChangedString(displayName: displayName, previousDisplayName: previousDisplayName,
                                        avatarURLString: nil, previousAvatarURLString: nil,
                                        member: member, memberIsYou: memberIsYou,
                                        sender: sender, senderIsYou: senderIsYou) + "\n" + ElementL10n.noticeAvatarChangedToo
        case (true, false, true):
            if let displayName, let previousDisplayName {
                return ElementL10n.noticeDisplayNameChangedFromByYou(displayName, previousDisplayName)
            } else if let displayName {
                return ElementL10n.noticeDisplayNameSetByYou(displayName)
            } else if let previousDisplayName {
                return ElementL10n.noticeDisplayNameRemovedByYou(previousDisplayName)
            } else {
                MXLog.error("The display name changed from nil to nil, shouldn't be possible.")
                return ElementL10n.noticeMemberNoChangesByYou
            }
        case (false, true, true):
            return ElementL10n.noticeAvatarUrlChangedByYou
        case (true, true, true):
            return profileChangedString(displayName: displayName, previousDisplayName: previousDisplayName,
                                        avatarURLString: nil, previousAvatarURLString: nil,
                                        member: member, memberIsYou: memberIsYou,
                                        sender: sender, senderIsYou: senderIsYou) + "\n" + ElementL10n.noticeAvatarChangedToo
        case (false, false, _):
            MXLog.error("Nothing changed, shouldn't be possible.")
            return ElementL10n.noticeMemberNoChangesByYou
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func buildString(for state: OtherState, stateKey: String?, sender: TimelineItemSender, isOutgoing: Bool) -> String? {
        let senderName = sender.displayName ?? sender.id
        
        switch state {
        case .roomAvatar(let url):
            switch (url, isOutgoing) {
            case (.some, false):
                return ElementL10n.noticeRoomAvatarChanged(senderName)
            case (nil, false):
                return ElementL10n.noticeRoomAvatarRemoved(senderName)
            case (.some, true):
                return ElementL10n.noticeRoomAvatarRemovedByYou
            case (nil, true):
                return ElementL10n.noticeRoomAvatarRemovedByYou
            }
        case .roomCreate:
            return isOutgoing ? ElementL10n.noticeRoomCreatedByYou : ElementL10n.noticeRoomCreated(senderName)
        case .roomEncryption:
            return ElementL10n.encryptionEnabled
        case .roomName(let name):
            switch (name, isOutgoing) {
            case (.some(let name), false):
                return ElementL10n.noticeRoomNameChanged(senderName, name)
            case (nil, false):
                return ElementL10n.noticeRoomNameRemoved(senderName)
            case (.some(let name), true):
                return ElementL10n.noticeRoomNameChangedByYou(name)
            case (nil, true):
                return ElementL10n.noticeRoomNameRemovedByYou
            }
        case .roomThirdPartyInvite(let displayName):
            guard let displayName else {
                MXLog.error("roomThirdPartyInvite undisplayable due to missing name.")
                return nil
            }
            
            if isOutgoing {
                return ElementL10n.noticeRoomThirdPartyInviteByYou(displayName)
            } else {
                return ElementL10n.noticeRoomThirdPartyInvite(senderName, displayName)
            }
        case .roomTopic(let topic):
            switch (topic, isOutgoing) {
            case (.some(let topic), false):
                return ElementL10n.noticeRoomTopicChanged(senderName, topic)
            case (nil, false):
                return ElementL10n.noticeRoomTopicRemoved(senderName)
            case (.some(let name), true):
                return ElementL10n.noticeRoomTopicChangedByYou(name)
            case (nil, true):
                return ElementL10n.noticeRoomTopicRemovedByYou
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
