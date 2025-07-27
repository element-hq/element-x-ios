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
        case mediaUploadPicker(mode: MediaPickerScreenMode, previousState: State)
        case mediaUploadPreview(mediaURLs: [URL], previousState: State)
        case emojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>, previousState: State)
        case mapNavigator(previousState: State)
        case messageForwarding(forwardingItem: MessageForwardingItem, previousState: State)
        case reportContent(itemID: TimelineItemIdentifier, senderID: String, previousState: State)
        case pollForm(previousState: State)
        case pollsHistory
        case pollsHistoryForm
        case rolesAndPermissions
        case pinnedEventsTimeline(previousState: State)
        case resolveSendFailure(previousState: State)
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
        var timelineController: TimelineControllerProtocol?
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
                
        case presentMediaUploadPicker(mode: MediaPickerScreenMode)
        case dismissMediaUploadPicker
        
        case presentMediaUploadPreview(mediaURLs: [URL])
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
            // Room
            case (_, .presentRoom):
                return .room
            case (_, .dismissFlow):
                return .complete
                
            case (.room, .presentReportContent(let itemID, let senderID)):
                return .reportContent(itemID: itemID, senderID: senderID, previousState: fromState)
                
            case (.room, .presentMediaUploadPicker(let mode)):
                return .mediaUploadPicker(mode: mode, previousState: fromState)
            
            case (.room, .presentMediaUploadPreview(let mediaURLs)):
                return .mediaUploadPreview(mediaURLs: mediaURLs, previousState: fromState)
                
            case (.room, .presentEmojiPicker(let itemID, let selectedEmoji)):
                return .emojiPicker(itemID: itemID, selectedEmojis: selectedEmoji, previousState: fromState)
            
            case (.room, .presentMessageForwarding(let forwardingItem)):
                return .messageForwarding(forwardingItem: forwardingItem, previousState: fromState)

            case (.room, .presentMapNavigator(_)):
                return .mapNavigator(previousState: fromState)
            
            case (.room, .presentPollForm):
                return .pollForm(previousState: fromState)
                
            case (.room, .presentResolveSendFailure):
                return .resolveSendFailure(previousState: fromState)
                
            case (.room, .presentPinnedEventsTimeline):
                return .pinnedEventsTimeline(previousState: fromState)
            case (.roomDetails, .presentPinnedEventsTimeline):
                return .pinnedEventsTimeline(previousState: fromState)
            case (.pinnedEventsTimeline(let previousState), .dismissPinnedEventsTimeline):
                return previousState
                
            // Thread
            case (.room, .presentThread(let itemID)):
                return .thread(itemID: itemID)
            case (.thread, .dismissThread):
                return .room
                
            case (.thread, .presentReportContent(let itemID, let senderID)):
                return .reportContent(itemID: itemID, senderID: senderID, previousState: fromState)
                
            case (.thread, .presentMediaUploadPicker(let mode)):
                return .mediaUploadPicker(mode: mode, previousState: fromState)
            
            case (.thread, .presentMediaUploadPreview(let mediaURLs)):
                return .mediaUploadPreview(mediaURLs: mediaURLs, previousState: fromState)
                
            case (.thread, .presentEmojiPicker(let itemID, let selectedEmoji)):
                return .emojiPicker(itemID: itemID, selectedEmojis: selectedEmoji, previousState: fromState)
            
            case (.thread, .presentMessageForwarding(let forwardingItem)):
                return .messageForwarding(forwardingItem: forwardingItem, previousState: fromState)

            case (.thread, .presentMapNavigator(_)):
                return .mapNavigator(previousState: fromState)
            
            case (.thread, .presentPollForm):
                return .pollForm(previousState: fromState)
                
            case (.thread, .presentResolveSendFailure):
                return .resolveSendFailure(previousState: fromState)
                
            // Room + Thread
                
            case (.mediaUploadPicker(_, let previousState), .dismissMediaUploadPicker):
                return previousState
                
            case (.emojiPicker(_, _, let previouState), .dismissEmojiPicker):
                return previouState
                
            case (.reportContent(_, _, let previousState), .dismissReportContent):
                return previousState
                
            case (.messageForwarding(_, let previousState), .dismissMessageForwarding):
                return previousState
                
            case (.mapNavigator(let previousState), .dismissMapNavigator):
                return previousState
                
            case (.pollForm(let previousState), .dismissPollForm):
                return previousState
                
            case (.resolveSendFailure(let previousState), .dismissResolveSendFailure):
                return previousState
                
            // Room Details
                
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
                
            case (.roomDetails, .presentRoomMembersList):
                return .roomMembersList
            case (.roomMembersList, .dismissRoomMembersList):
                return .roomDetails(isRoot: false)
                
            case (.roomDetails, .presentNotificationSettingsScreen):
                return .notificationSettings
            case (.notificationSettings, .dismissNotificationSettingsScreen):
                return .roomDetails(isRoot: false)
                
            case (.roomDetails, .presentPollsHistory):
                return .pollsHistory
            case (.pollsHistory, .dismissPollsHistory):
                return .roomDetails(isRoot: false)
                
            case (.roomDetails, .presentRolesAndPermissionsScreen):
                return .rolesAndPermissions
            case (.rolesAndPermissions, .dismissRolesAndPermissionsScreen):
                return .roomDetails(isRoot: false)
                
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
                
            // Join room
                
            case (_, .presentJoinRoomScreen):
                return .joinRoomScreen
            case (_, .dismissJoinRoomScreen):
                return .complete
                
            case (.joinRoomScreen, .presentDeclineAndBlockScreen):
                return .declineAndBlockScreen
            case (.declineAndBlockScreen, .dismissDeclineAndBlockScreen):
                return .joinRoomScreen
                
            // Other
            
            case (_, .startChildFlow(let roomID, _, _)):
                return .presentingChild(childRoomID: roomID, previousState: fromState)
            case (.presentingChild(_, let previousState), .dismissChildFlow):
                return previousState
                    
            case (_, .presentRoomMemberDetails(userID: let userID)):
                return .roomMemberDetails(userID: userID, previousState: fromState)
            case (.roomMemberDetails(_, let previousState), .dismissRoomMemberDetails):
                return previousState
                
            case (_, .presentKnockRequestsListScreen):
                return .knockRequestsList(previousState: fromState)
            case (.knockRequestsList(let previousState), .dismissKnockRequestsListScreen):
                return previousState
                
            case (.mediaUploadPreview(_, let previousState), .dismissMediaUploadPreview):
                return previousState
                
            case (.notificationSettings, .presentGlobalNotificationSettingsScreen):
                return .globalNotificationSettings
            case (.globalNotificationSettings, .dismissGlobalNotificationSettingsScreen):
                return .notificationSettings
            
            case (.roomMemberDetails(_, let previousState), .presentUserProfile(let userID)):
                return .userProfile(userID: userID, previousState: previousState)
            case (.userProfile(_, let previousState), .dismissUserProfile):
                return previousState
                
            case (.pollsHistory, .presentPollForm):
                return .pollsHistoryForm
            case (.pollsHistoryForm, .dismissPollForm):
                return .pollsHistory
                
            case (.mediaUploadPicker(_, let previousMediaUploadPickerState), .presentMediaUploadPreview(let mediaURLs)):
                return .mediaUploadPreview(mediaURLs: mediaURLs, previousState: previousMediaUploadPickerState)
                
            case (_, .presentInviteUsersScreen):
                return .inviteUsersScreen(previousState: fromState)
            case (.inviteUsersScreen(let previousState), .dismissInviteUsersScreen):
                return previousState
            
            default:
                return nil
            }
        }
    }
}
