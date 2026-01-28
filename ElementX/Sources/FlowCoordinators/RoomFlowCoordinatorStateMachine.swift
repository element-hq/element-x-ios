//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        case thread(rootEventID: String, focusEvent: FocusEvent?)
        
        var focusedEvent: FocusEvent? {
            switch self {
            case .eventFocus(let focusEvent):
                focusEvent
            case .thread(let rootEventID, let focusEvent):
                // Since this enum is for the room and not the threaded timeline,
                // we will focus the thread root event id, and not the event id itself
                // which will be done at the thread presentation level
                if let focusEvent {
                    .init(eventID: rootEventID, shouldSetPin: focusEvent.shouldSetPin)
                } else {
                    nil
                }
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
        case thread(threadRootEventID: String, previousState: State)
        case roomDetails(isRoot: Bool)
        case roomDetailsEditScreen
        case notificationSettings
        case globalNotificationSettings
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
        case manageAuthorizedSpacesScreen(previousState: State)
        case reportRoom(previousState: State)
        case declineAndBlockScreen
        case transferOwnershipScreen(previousState: State)
        
        /// A child flow is in progress.
        case presentingChild(childRoomID: String, previousState: State)
        /// The flow is complete and is handing control of the stack back to its parent.
        case complete
        
        /// A space flow is in progress
        case spaceFlow(previousState: State)
        /// A members flow is in progress
        case membersFlow(previousState: State)
    }
    
    struct EventUserInfo {
        let animated: Bool
        var timelineController: TimelineControllerProtocol?
        var spaceRoomListProxy: SpaceRoomListProxyProtocol?
        var authorizedSpacesSelection: AuthorizedSpacesSelection?
    }

    enum Event: EventType {
        case presentJoinRoomScreen(via: [String])
        case dismissJoinRoomScreen
        case joinedSpace
        
        case presentRoom(presentationAction: PresentationAction?)
        case dismissFlow
        
        case presentThread(threadRootEventID: String, focusEventID: String?)
        case dismissThread
        
        case startSpaceFlow
        case finishedSpaceFlow
        
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
        
        case presentManageAuthorizedSpacesScreen
        case dismissedManageAuthorizedSpacesScreen
        
        case presentReportRoomScreen
        case dismissReportRoomScreen
        
        case presentDeclineAndBlockScreen(userID: String)
        case dismissDeclineAndBlockScreen
        
        case presentTransferOwnershipScreen
        case dismissedTransferOwnershipScreen
        
        case startMembersFlow(entryPoint: RoomMembersFlowCoordinatorEntryPoint)
        case stopMembersFlow
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
            case (.mediaEventsTimeline, .presentMessageForwarding(forwardingItem: let forwardingItem)):
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
            case (.room, .presentThread(let threadRootEventID, _)):
                return .thread(threadRootEventID: threadRootEventID, previousState: fromState)
            case (.thread, .presentThread(let threadRootEventID, _)):
                return .thread(threadRootEventID: threadRootEventID, previousState: fromState)
            case (.thread(_, let previousState), .dismissThread):
                return previousState
                
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
                
            case (.securityAndPrivacy, .presentManageAuthorizedSpacesScreen):
                return .manageAuthorizedSpacesScreen(previousState: fromState)
            case (.manageAuthorizedSpacesScreen(let previousState), .dismissedManageAuthorizedSpacesScreen):
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
            case (_, .joinedSpace):
                return .complete
                
            case (.joinRoomScreen, .presentDeclineAndBlockScreen):
                return .declineAndBlockScreen
            case (.declineAndBlockScreen, .dismissDeclineAndBlockScreen):
                return .joinRoomScreen
                
            // Other
                
            case (_, .startMembersFlow):
                return .membersFlow(previousState: fromState)
            case (.membersFlow(let previousState), .stopMembersFlow):
                return previousState
            
            case (_, .startChildFlow(let roomID, _, _)):
                return .presentingChild(childRoomID: roomID, previousState: fromState)
            case (.presentingChild(_, let previousState), .dismissChildFlow):
                return previousState
                
            case (.presentingChild(_, let previousState), .startSpaceFlow):
                return .spaceFlow(previousState: previousState)
            case (.spaceFlow(let previousState), .finishedSpaceFlow):
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
                
            case (_, .presentTransferOwnershipScreen):
                return .transferOwnershipScreen(previousState: fromState)
            case (.transferOwnershipScreen(let previousState), .dismissedTransferOwnershipScreen):
                return previousState
            
            default:
                return nil
            }
        }
    }
}
