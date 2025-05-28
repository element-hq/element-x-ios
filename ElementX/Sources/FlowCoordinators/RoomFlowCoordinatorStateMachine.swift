//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftState

extension RoomFlowCoordinator {
    struct HashableRoomMemberWrapper: Hashable {
        let value: RoomMemberProxyProtocol

        static func == (lhs: HashableRoomMemberWrapper, rhs: HashableRoomMemberWrapper) -> Bool {
            lhs.value.userID == rhs.value.userID
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(value.userID)
        }
    }
    
    enum PresentationAction: Hashable {
        case eventFocus(FocusEvent)
        case share(ShareExtensionPayload)
        
        var focusedEvent: FocusEvent? {
            switch self {
            case .eventFocus(let focusEvent):
                focusEvent
            default:
                nil
            }
        }
        
        var sharedText: String? {
            switch self {
            case .share(.text(_, let text)):
                text
            default:
                nil
            }
        }
    }

    indirect enum State: StateType {
        case initial
        case joinRoomScreen
        case room
        case thread(itemID: TimelineItemIdentifier)
        case roomDetails(isRoot: Bool)
        case roomDetailsEditScreen
        case notificationSettings
        case globalNotificationSettings
        case roomMembersList
        case roomMemberDetails(userID: String, previousState: State)
        case userProfile(userID: String, previousState: State)
        case inviteUsersScreen(previousState: State)
        case mediaUploadPicker(source: MediaPickerScreenSource)
        case mediaUploadPreview(fileURL: URL)
        case emojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
        case mapNavigator
        case messageForwarding(forwardingItem: MessageForwardingItem)
        case reportContent(itemID: TimelineItemIdentifier, senderID: String)
        case pollForm
        case pollsHistory
        case pollsHistoryForm
        case rolesAndPermissions
        case pinnedEventsTimeline(previousState: State)
        case resolveSendFailure
        case knockRequestsList(previousState: State)
        case mediaEventsTimeline(previousState: State)
        case securityAndPrivacy(previousState: State)
        case reportRoom(previousState: State)
        case declineAndBlockScreen
        
        /// A child flow is in progress.
        case presentingChild(childRoomID: String, previousState: State)
        /// The flow is complete and is handing control of the stack back to its parent.
        case complete
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    enum Event: EventType {
        case presentJoinRoomScreen(via: [String])
        case dismissJoinRoomScreen
        
        case presentRoom(presentationAction: PresentationAction?)
        case dismissFlow
        
        case presentThread(itemID: TimelineItemIdentifier)
        case dismissThread
        
        case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
        case dismissReportContent
        
        case presentRoomDetails
        case dismissRoomDetails
        
        case presentRoomDetailsEditScreen
        case dismissRoomDetailsEditScreen
        
        case presentNotificationSettingsScreen
        case dismissNotificationSettingsScreen
        
        case presentGlobalNotificationSettingsScreen
        case dismissGlobalNotificationSettingsScreen
        
        case presentRoomMembersList
        case dismissRoomMembersList
        
        case presentRoomMemberDetails(userID: String)
        case dismissRoomMemberDetails
        
        case presentUserProfile(userID: String)
        case dismissUserProfile
        
        case presentInviteUsersScreen
        case dismissInviteUsersScreen
                
        case presentMediaUploadPicker(source: MediaPickerScreenSource)
        case dismissMediaUploadPicker
        
        case presentMediaUploadPreview(fileURL: URL)
        case dismissMediaUploadPreview
        
        case presentEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
        case dismissEmojiPicker

        case presentMapNavigator(interactionMode: StaticLocationInteractionMode)
        case dismissMapNavigator
        
        case presentMessageForwarding(forwardingItem: MessageForwardingItem)
        case dismissMessageForwarding

        case presentPollForm(mode: PollFormMode)
        case dismissPollForm
        
        case presentPollsHistory
        case dismissPollsHistory
        
        case presentRolesAndPermissionsScreen
        case dismissRolesAndPermissionsScreen
        
        case presentPinnedEventsTimeline
        case dismissPinnedEventsTimeline
        
        case presentResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, sendHandle: SendHandleProxy)
        case dismissResolveSendFailure
        
        case startChildFlow(roomID: String, via: [String], entryPoint: RoomFlowCoordinatorEntryPoint)
        case dismissChildFlow
        
        case presentKnockRequestsListScreen
        case dismissKnockRequestsListScreen
        
        case presentMediaEventsTimeline
        case dismissMediaEventsTimeline
        
        case presentSecurityAndPrivacyScreen
        case dismissSecurityAndPrivacyScreen
        
        case presentReportRoomScreen
        case dismissReportRoomScreen
        
        case presentDeclineAndBlockScreen(userID: String)
        case dismissDeclineAndBlockScreen
    }
    
    // swiftlint:disable:next function_body_length
    func addRouteMapping(stateMachine: StateMachine<State, Event>) {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (_, .presentJoinRoomScreen):
                return .joinRoomScreen
            case (_, .dismissJoinRoomScreen):
                return .complete
                
            case (_, .presentRoom):
                return .room
            case (_, .dismissFlow):
                return .complete
                
            case (_, .presentThread(let itemID)):
                return .thread(itemID: itemID)
            case (_, .dismissThread):
                return .room
                
            case (.initial, .presentRoomDetails):
                return .roomDetails(isRoot: true)
            case (.room, .presentRoomDetails):
                return .roomDetails(isRoot: false)
            case (.roomDetails, .dismissRoomDetails):
                return .room
                
            case (.roomDetails, .presentRoomDetailsEditScreen):
                return .roomDetailsEditScreen
            case (.roomDetailsEditScreen, .dismissRoomDetailsEditScreen):
                return .roomDetails(isRoot: false)
                
            case (.roomDetails, .presentNotificationSettingsScreen):
                return .notificationSettings
            case (.notificationSettings, .dismissNotificationSettingsScreen):
                return .roomDetails(isRoot: false)
                
            case (.notificationSettings, .presentGlobalNotificationSettingsScreen):
                return .globalNotificationSettings
            case (.globalNotificationSettings, .dismissGlobalNotificationSettingsScreen):
                return .notificationSettings
                
            case (.roomDetails, .presentRoomMembersList):
                return .roomMembersList
            case (.roomMembersList, .dismissRoomMembersList):
                return .roomDetails(isRoot: false)

            case (_, .presentRoomMemberDetails(userID: let userID)):
                return .roomMemberDetails(userID: userID, previousState: fromState)
            case (.roomMemberDetails(_, let previousState), .dismissRoomMemberDetails):
                return previousState
            
            case (.roomMemberDetails(_, let previousState), .presentUserProfile(let userID)):
                return .userProfile(userID: userID, previousState: previousState)
            case (.userProfile(_, let previousState), .dismissUserProfile):
                return previousState
                
            case (_, .presentInviteUsersScreen):
                return .inviteUsersScreen(previousState: fromState)
            case (.inviteUsersScreen(let previousState), .dismissInviteUsersScreen):
                return previousState
                
            case (.room, .presentReportContent(let itemID, let senderID)):
                return .reportContent(itemID: itemID, senderID: senderID)
            case (.reportContent, .dismissReportContent):
                return .room
                
            case (.room, .presentMediaUploadPicker(let source)):
                return .mediaUploadPicker(source: source)
            case (.mediaUploadPicker, .dismissMediaUploadPicker):
                return .room
                
            case (.mediaUploadPicker, .presentMediaUploadPreview(let fileURL)):
                return .mediaUploadPreview(fileURL: fileURL)
            case (.room, .presentMediaUploadPreview(let fileURL)):
                return .mediaUploadPreview(fileURL: fileURL)
            case (.mediaUploadPreview, .dismissMediaUploadPreview):
                return .room
                
            case (.room, .presentEmojiPicker(let itemID, let selectedEmoji)):
                return .emojiPicker(itemID: itemID, selectedEmojis: selectedEmoji)
            case (.emojiPicker, .dismissEmojiPicker):
                return .room

            case (.room, .presentMessageForwarding(let forwardingItem)):
                return .messageForwarding(forwardingItem: forwardingItem)
            case (.messageForwarding, .dismissMessageForwarding):
                return .room

            case (.room, .presentMapNavigator):
                return .mapNavigator
            case (.mapNavigator, .dismissMapNavigator):
                return .room
            
            case (.room, .presentPollForm):
                return .pollForm
            case (.pollForm, .dismissPollForm):
                return .room
                
            case (.room, .presentPinnedEventsTimeline):
                return .pinnedEventsTimeline(previousState: fromState)
            case (.roomDetails, .presentPinnedEventsTimeline):
                return .pinnedEventsTimeline(previousState: fromState)
            case (.pinnedEventsTimeline(let previousState), .dismissPinnedEventsTimeline):
                return previousState
                
            case (.roomDetails, .presentPollsHistory):
                return .pollsHistory
            case (.pollsHistory, .dismissPollsHistory):
                return .roomDetails(isRoot: false)
            
            case (.pollsHistory, .presentPollForm):
                return .pollsHistoryForm
            case (.pollsHistoryForm, .dismissPollForm):
                return .pollsHistory
            
            case (.roomDetails, .presentRolesAndPermissionsScreen):
                return .rolesAndPermissions
            case (.rolesAndPermissions, .dismissRolesAndPermissionsScreen):
                return .roomDetails(isRoot: false)
            
            case (.room, .presentResolveSendFailure):
                return .resolveSendFailure
            case (.resolveSendFailure, .dismissResolveSendFailure):
                return .room
            
            case (_, .startChildFlow(let roomID, _, _)):
                return .presentingChild(childRoomID: roomID, previousState: fromState)
            case (.presentingChild(_, let previousState), .dismissChildFlow):
                return previousState
                
            case (_, .presentKnockRequestsListScreen):
                return .knockRequestsList(previousState: fromState)
            case (.knockRequestsList(let previousState), .dismissKnockRequestsListScreen):
                return previousState
                
            case (.roomDetails, .presentMediaEventsTimeline):
                return .mediaEventsTimeline(previousState: fromState)
            case (.mediaEventsTimeline(let previousState), .dismissMediaEventsTimeline):
                return previousState
                
            case (.roomDetails, .presentSecurityAndPrivacyScreen):
                return .securityAndPrivacy(previousState: fromState)
            case (.securityAndPrivacy(let previousState), .dismissSecurityAndPrivacyScreen):
                return previousState
                
            case (.roomDetails, .presentReportRoomScreen):
                return .reportRoom(previousState: fromState)
            case (.reportRoom(let previousState), .dismissReportRoomScreen):
                return previousState
                
            case (.joinRoomScreen, .presentDeclineAndBlockScreen):
                return .declineAndBlockScreen
            case (.declineAndBlockScreen, .dismissDeclineAndBlockScreen):
                return .joinRoomScreen
            
            default:
                return nil
            }
        }
    }
}
