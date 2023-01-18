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
    static func buildStateTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                          isOutgoing: Bool,
                                          avatarImage: UIImage?,
                                          stateKey: String,
                                          content: OtherState) -> RoomTimelineItemProtocol {
        buildDefault(eventItemProxy: eventItemProxy, text: UUID().uuidString, isOutgoing: isOutgoing, avatarImage: avatarImage)
    }
    
    static func buildStateMembershipChangeTimelineItemFor(eventItemProxy: EventTimelineItemProxy,
                                                          isOutgoing: Bool,
                                                          avatarImage: UIImage?,
                                                          change: MembershipChange) -> RoomTimelineItemProtocol {
        let text = textForMembershipChange(change, member: eventItemProxy.senderDisplayName ?? eventItemProxy.sender)
        return buildDefault(eventItemProxy: eventItemProxy, text: text, isOutgoing: isOutgoing, avatarImage: avatarImage)
    }
    
    // MARK: - Private
    
    private static func buildDefault(eventItemProxy: EventTimelineItemProxy, text: String, isOutgoing: Bool, avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        StateRoomTimelineItem(id: eventItemProxy.id,
                              text: text,
                              timestamp: eventItemProxy.timestamp.formatted(date: .omitted, time: .shortened),
                              groupState: .single,
                              isOutgoing: isOutgoing,
                              isEditable: false,
                              senderId: eventItemProxy.sender,
                              senderDisplayName: eventItemProxy.senderDisplayName,
                              senderAvatarURL: eventItemProxy.senderAvatarURL,
                              senderAvatar: avatarImage)
    }
    
    private static func textForMembershipChange(_ change: MembershipChange, member: String) -> String {
        switch change {
        case .none:
            break
        case .error:
            break
        case .joined:
            return ElementL10n.noticeRoomJoin(member)
        case .left:
            return ElementL10n.noticeRoomLeave(member)
        case .banned:
            break
        case .unbanned:
            break
        case .kicked:
            break
        case .invited:
            break
        case .kickedAndBanned:
            break
        case .invitationAccepted:
            break
        case .invitationRejected:
            break
        case .invitationRevoked:
            break
        case .knocked:
            break
        case .knockAccepted:
            break
        case .knockRetracted:
            break
        case .knockDenied:
            break
        case .profileChanged(let displayName, let previousDisplayName, let avatarURL, let previousAvatarURL):
            break
        case .notImplemented:
            break
        case .unknown(let membershipState, let displayName, let avatarURLString):
            break
        }
        
        return ""
    }
}
