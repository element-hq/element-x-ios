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

struct RoomStateTimelineItemFactory {
    let userID: String
    
    func buildStateTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                   content: OtherState,
                                   stateKey: String,
                                   sender: TimelineItemSender,
                                   isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let text = textForOtherState(content, stateKey: stateKey, sender: sender, isOutgoing: isOutgoing)
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, sender: sender, isOutgoing: isOutgoing)
    }
    
    func buildStateMembershipChangeTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                                   member: String,
                                                   change: MembershipChange,
                                                   sender: TimelineItemSender,
                                                   isOutgoing: Bool) -> RoomTimelineItemProtocol {
        let text = textForMembershipChange(change, member: member, sender: eventItemProxy.sender, isOutgoing: isOutgoing)
        return buildStateTimelineItem(eventItemProxy: eventItemProxy, text: text, sender: sender, isOutgoing: isOutgoing)
    }
    
    // MARK: - Private
    
    private func buildStateTimelineItem(eventItemProxy: EventTimelineItemProxy, text: String, sender: TimelineItemSender, isOutgoing: Bool) -> RoomTimelineItemProtocol {
        StateRoomTimelineItem(id: eventItemProxy.id,
                              text: text,
                              timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                              groupState: .single,
                              isOutgoing: isOutgoing,
                              isEditable: false,
                              sender: sender)
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func textForMembershipChange(_ change: MembershipChange, member: String, sender: TimelineItemSender, isOutgoing: Bool) -> String {
        let senderName = sender.displayName ?? sender.id
        let senderIsYou = isOutgoing
        let memberIsYou = member == userID
        
        switch change {
        case .none:
            return senderIsYou ? ElementL10n.noticeMemberNoChangesByYou : ElementL10n.noticeMemberNoChanges(member)
        case .error:
            return ElementL10n.noticeRoomMembershipError(member)
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
        case .notImplemented:
            return ElementL10n.noticeRoomUnknownChange(sender)
        case .unknown(_, let displayName, _):
            return ElementL10n.noticeRoomUnknownMembershipChange(displayName ?? member)
        }
        
        return ""
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
                return ElementL10n.noticeMemberNoChanges(member)
            }
        case (false, true, false):
            return ElementL10n.noticeAvatarUrlChanged(member)
        case (true, true, false):
            return profileChangedString(displayName: displayName, previousDisplayName: previousDisplayName,
                                        avatarURLString: nil, previousAvatarURLString: nil,
                                        member: member, memberIsYou: memberIsYou,
                                        sender: sender, senderIsYou: senderIsYou) + "\n" + ElementL10n.noticeAvatarChangedToo
        case (false, false, false):
            return ElementL10n.noticeMemberNoChanges(member)
        case (true, false, true):
            if let displayName, let previousDisplayName {
                return ElementL10n.noticeDisplayNameChangedFromByYou(displayName, previousDisplayName)
            } else if let displayName {
                return ElementL10n.noticeDisplayNameSetByYou(displayName)
            } else if let previousDisplayName {
                return ElementL10n.noticeDisplayNameRemovedByYou(previousDisplayName)
            } else {
                return ElementL10n.noticeMemberNoChangesByYou
            }
        case (false, true, true):
            return ElementL10n.noticeAvatarUrlChangedByYou
        case (true, true, true):
            return profileChangedString(displayName: displayName, previousDisplayName: previousDisplayName,
                                        avatarURLString: nil, previousAvatarURLString: nil,
                                        member: member, memberIsYou: memberIsYou,
                                        sender: sender, senderIsYou: senderIsYou) + "\n" + ElementL10n.noticeAvatarChangedToo
        case (false, false, true):
            return ElementL10n.noticeMemberNoChangesByYou
        }
    }
    
    private func textForOtherState(_ content: OtherState, stateKey: String?, sender: TimelineItemSender, isOutgoing: Bool) -> String {
        return "State change"
    }
}
