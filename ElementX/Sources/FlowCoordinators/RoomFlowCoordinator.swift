//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState
import SwiftUI
import UserNotifications

enum RoomFlowCoordinatorAction: Equatable {
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
    case finished
    
    static func == (lhs: RoomFlowCoordinatorAction, rhs: RoomFlowCoordinatorAction) -> Bool {
        switch (lhs, rhs) {
        case (.presentCallScreen(let lhsRoomProxy), .presentCallScreen(let rhsRoomProxy)):
            lhsRoomProxy.id == rhsRoomProxy.id
        case (.finished, .finished):
            true
        default:
            false
        }
    }
}

/// A value that represents where the room flow will be started.
enum RoomFlowCoordinatorEntryPoint: Hashable {
    /// The flow will start by showing the room directly.
    case room
    /// The flow will start by showing the room, focussing on the supplied event ID.
    case eventID(String)
    /// The flow will start by showing the room's details.
    case roomDetails
    /// An external media share request
    case share(ShareExtensionPayload)
    
    var isEventID: Bool {
        guard case .eventID = self else { return false }
        return true
    }
}

struct FocusEvent: Hashable {
    /// The event ID that the timeline should be focussed around
    let eventID: String
    /// if the focus is coming from the pinned timeline, this should also update the pin banner
    let shouldSetPin: Bool
}

private enum PresentationAction: Hashable {
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

// swiftlint:disable:next type_body_length
class RoomFlowCoordinator: FlowCoordinatorProtocol {
    private let roomID: String
    private let userSession: UserSessionProtocol
    private let isChildFlow: Bool
    private let timelineControllerFactory: TimelineControllerFactoryProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let emojiProvider: EmojiProviderProtocol
    private let ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var roomProxy: JoinedRoomProxyProtocol!
    
    private var roomScreenCoordinator: RoomScreenCoordinator?
    private weak var joinRoomScreenCoordinator: JoinRoomScreenCoordinator?
    
    // periphery:ignore - used to avoid deallocation
    private var rolesAndPermissionsFlowCoordinator: RoomRolesAndPermissionsFlowCoordinator?
    // periphery:ignore - used to avoid deallocation
    private var pinnedEventsTimelineFlowCoordinator: PinnedEventsTimelineFlowCoordinator?
    // periphery:ignore - used to avoid deallocation
    private var mediaEventsTimelineFlowCoordinator: MediaEventsTimelineFlowCoordinator?
    // periphery:ignore - used to avoid deallocation
    private var childRoomFlowCoordinator: RoomFlowCoordinator?
    
    private let stateMachine: StateMachine<State, Event> = .init(state: .initial)
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var timelineController: TimelineControllerProtocol?
    
    init(roomID: String,
         userSession: UserSessionProtocol,
         isChildFlow: Bool,
         timelineControllerFactory: TimelineControllerFactoryProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         emojiProvider: EmojiProviderProtocol,
         ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) async {
        self.roomID = roomID
        self.userSession = userSession
        self.isChildFlow = isChildFlow
        self.timelineControllerFactory = timelineControllerFactory
        self.navigationStackCoordinator = navigationStackCoordinator
        self.emojiProvider = emojiProvider
        self.ongoingCallRoomIDPublisher = ongoingCallRoomIDPublisher
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        setupStateMachine()
        
        analytics.signpost.beginRoomFlow(roomID)
    }
        
    // MARK: - FlowCoordinatorProtocol
    
    func start() {
        fatalError("This flow coordinator expect a route")
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        guard stateMachine.state != .complete else {
            fatalError("This flow coordinator is `finished` ☠️")
        }
        
        switch appRoute {
        case .room(let roomID, let via):
            Task {
                await handleRoomRoute(roomID: roomID, via: via, animated: animated)
            }
        case .childRoom(let roomID, let via):
            if case .presentingChild = stateMachine.state, let childRoomFlowCoordinator {
                childRoomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else if roomID != roomProxy.id {
                stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: via, entryPoint: .room), userInfo: EventUserInfo(animated: animated))
            } else {
                MXLog.info("Ignoring presentation of the same room as a child of this one.")
            }
        case .roomDetails(let roomID):
            guard roomID == self.roomID else { fatalError("Navigation route doesn't belong to this room flow.") }
            
            Task {
                if roomProxy == nil {
                    guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
                        return
                    }
                    
                    await storeAndSubscribeToRoomProxy(roomProxy)
                }
                
                stateMachine.tryEvent(.presentRoomDetails, userInfo: EventUserInfo(animated: animated))
            }
        case .roomMemberDetails(let userID):
            // Always assume this will be presented on the child, external permalinks to a user aren't for a room member.
            if case .presentingChild = stateMachine.state, let childRoomFlowCoordinator {
                childRoomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID), userInfo: EventUserInfo(animated: animated))
            }
        case .event(let eventID, let roomID, let via):
            Task {
                await handleRoomRoute(roomID: roomID,
                                      via: via,
                                      presentationAction: .eventFocus(.init(eventID: eventID, shouldSetPin: false)),
                                      animated: animated)
            }
        case .childEvent(let eventID, let roomID, let via):
            if case .presentingChild = stateMachine.state, let childRoomFlowCoordinator {
                childRoomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else if roomID != roomProxy.id {
                stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: via, entryPoint: .eventID(eventID)), userInfo: EventUserInfo(animated: animated))
            } else {
                roomScreenCoordinator?.focusOnEvent(.init(eventID: eventID, shouldSetPin: false))
            }
        case .share(let payload):
            guard let roomID = payload.roomID, roomID == self.roomID else {
                fatalError("Navigation route doesn't belong to this room flow.")
            }
            
            Task {
                await handleRoomRoute(roomID: roomID,
                                      via: [],
                                      presentationAction: .share(payload),
                                      animated: animated)
            }
        case .roomAlias, .childRoomAlias, .eventOnRoomAlias, .childEventOnRoomAlias:
            break // These are converted to a room ID route one level above.
        case .roomList, .userProfile, .call, .genericCallLink, .settings, .chatBackupSettings:
            break // These routes can't be handled.
        }
    }
    
    private func presentCallScreen(roomID: String) async {
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            return
        }
        
        actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
    }
    
    private func handleRoomRoute(roomID: String, via: [String], presentationAction: PresentationAction? = nil, animated: Bool) async {
        guard roomID == self.roomID else { fatalError("Navigation route doesn't belong to this room flow.") }
        
        showLoadingIndicator(delay: .seconds(0.5))
        defer { hideLoadingIndicator() }
        
        guard let room = await userSession.clientProxy.roomForIdentifier(roomID) else {
            stateMachine.tryEvent(.presentJoinRoomScreen(via: via), userInfo: EventUserInfo(animated: animated))
            return
        }
        
        switch room {
        case .joined(let roomProxy):
            await storeAndSubscribeToRoomProxy(roomProxy)
            stateMachine.tryEvent(.presentRoom(presentationAction: presentationAction), userInfo: EventUserInfo(animated: animated))
        default:
            stateMachine.tryEvent(.presentJoinRoomScreen(via: via), userInfo: EventUserInfo(animated: animated))
        }
    }

    func clearRoute(animated: Bool) {
        guard stateMachine.state != .initial else {
            return
        }
        
        stateMachine.tryEvent(.dismissFlow, userInfo: EventUserInfo(animated: animated))
    }
    
    // MARK: - Private
    
    private func storeAndSubscribeToRoomProxy(_ roomProxy: JoinedRoomProxyProtocol) async {
        if let oldRoomProxy = self.roomProxy {
            if oldRoomProxy.id != roomProxy.id {
                fatalError("Trying to create different room proxies for the same flow coordinator")
            }
            
            MXLog.warning("Found an existing proxy, returning.")
            return
        }
                
        await roomProxy.subscribeForUpdates()
        
        // Make sure not to set this until after the subscription has succeeded, otherwise the
        // early return above could result in trying to access the room's timeline provider
        // before it has been set which triggers a fatal error.
        self.roomProxy = roomProxy
    }
    
    // swiftlint:disable:next function_body_length
    private func setupStateMachine() {
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
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            let animated = (context.userInfo as? EventUserInfo)?.animated ?? true
            
            switch (context.fromState, context.event, context.toState) {
            case (_, .presentJoinRoomScreen(let via), .joinRoomScreen):
                presentJoinRoomScreen(via: via, animated: true)
            case (_, .dismissJoinRoomScreen, .complete):
                dismissFlow(animated: animated)
                
            case (_, .presentRoom(let presentationAction), .room):
                Task {
                    await self.presentRoom(fromState: context.fromState,
                                           presentationAction: presentationAction,
                                           animated: animated)
                }
            case (_, .dismissFlow, .complete):
                dismissFlow(animated: animated)
            
            case (.initial, .presentRoomDetails, .roomDetails(let isRoot)),
                 (.room, .presentRoomDetails, .roomDetails(let isRoot)),
                 (.roomDetails, .presentRoomDetails, .roomDetails(let isRoot)):
                Task { await self.presentRoomDetails(isRoot: isRoot, animated: animated) }
            case (.roomDetails, .dismissRoomDetails, .room):
                break
                
            case (.roomDetails, .presentRoomDetailsEditScreen, .roomDetailsEditScreen):
                presentRoomDetailsEditScreen()
            case (.roomDetailsEditScreen, .dismissRoomDetailsEditScreen, .roomDetails):
                break
                
            case (.roomDetails, .presentNotificationSettingsScreen, .notificationSettings):
                presentNotificationSettingsScreen()
            case (.notificationSettings, .dismissNotificationSettingsScreen, .roomDetails):
                break
                
            case (.notificationSettings, .presentGlobalNotificationSettingsScreen, .globalNotificationSettings):
                presentGlobalNotificationSettingsScreen()
            case (.globalNotificationSettings, .dismissGlobalNotificationSettingsScreen, .notificationSettings):
                break
                
            case (.roomDetails, .presentRoomMembersList, .roomMembersList):
                presentRoomMembersList()
            case (.roomMembersList, .dismissRoomMembersList, .roomDetails):
                break
                
            case (.room, .presentRoomMemberDetails, .roomMemberDetails(let userID, _)):
                presentRoomMemberDetails(userID: userID)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .room):
                break
                
            case (.roomMembersList, .presentRoomMemberDetails, .roomMemberDetails(let userID, _)):
                presentRoomMemberDetails(userID: userID)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .roomMembersList):
                break
            
            case (.roomMemberDetails, .presentUserProfile(let userID), .userProfile):
                replaceRoomMemberDetailsWithUserProfile(userID: userID)
            case (.userProfile, .dismissUserProfile, .room):
                break
                
            case (.roomDetails, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
            case (.inviteUsersScreen, .dismissInviteUsersScreen, .roomDetails):
                break
                
            case (.roomMembersList, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
            case (.inviteUsersScreen, .dismissInviteUsersScreen, .roomMembersList):
                break
                
            case (.room, .presentReportContent, .reportContent(let itemID, let senderID)):
                presentReportContent(for: itemID, from: senderID)
            case (.reportContent, .dismissReportContent, .room):
                break
                
            case (.room, .presentMediaUploadPicker, .mediaUploadPicker(let source)):
                presentMediaUploadPickerWithSource(source)
            case (.mediaUploadPicker, .dismissMediaUploadPicker, .room):
                break
                
            case (.mediaUploadPicker, .presentMediaUploadPreview, .mediaUploadPreview(let fileURL)):
                presentMediaUploadPreviewScreen(for: fileURL, animated: animated)
            case (.room, .presentMediaUploadPreview, .mediaUploadPreview(let fileURL)):
                presentMediaUploadPreviewScreen(for: fileURL, animated: animated)
            case (.mediaUploadPreview, .dismissMediaUploadPreview, .room):
                break
                
            case (.room, .presentEmojiPicker, .emojiPicker(let itemID, let selectedEmoji)):
                presentEmojiPicker(for: itemID, selectedEmoji: selectedEmoji)
            case (.emojiPicker, .dismissEmojiPicker, .room):
                break
                
            case (.room, .presentMessageForwarding(let forwardingItem), .messageForwarding):
                presentMessageForwarding(with: forwardingItem)
            case (.messageForwarding, .dismissMessageForwarding, .room):
                break

            case (.room, .presentMapNavigator(let mode), .mapNavigator):
                presentMapNavigator(interactionMode: mode)
            case (.mapNavigator, .dismissMapNavigator, .room):
                break

            case (.room, .presentPollForm(let mode), .pollForm):
                presentPollForm(mode: mode)
            case (.pollForm, .dismissPollForm, .room):
                break
                
            case (.room, .presentPinnedEventsTimeline, .pinnedEventsTimeline):
                startPinnedEventsTimelineFlow()
            case (.pinnedEventsTimeline, .dismissPinnedEventsTimeline, .room):
                break

            case (.roomDetails, .presentPollsHistory, .pollsHistory):
                presentPollsHistory()
            case (.pollsHistory, .dismissPollsHistory, .roomDetails):
                break
                
            case (.roomDetails, .presentPinnedEventsTimeline, .pinnedEventsTimeline):
                startPinnedEventsTimelineFlow()
            case (.pinnedEventsTimeline, .dismissPinnedEventsTimeline, .roomDetails):
                break
        
            case (.pollsHistory, .presentPollForm(let mode), .pollsHistoryForm):
                presentPollForm(mode: mode)
            case (.pollsHistoryForm, .dismissPollForm, .pollsHistory):
                break
            
            case (.roomDetails, .presentRolesAndPermissionsScreen, .rolesAndPermissions):
                presentRolesAndPermissionsScreen()
            case (.rolesAndPermissions, .dismissRolesAndPermissionsScreen, .roomDetails):
                rolesAndPermissionsFlowCoordinator = nil
                
            case (.roomDetails, .presentRoomMemberDetails(let userID), .roomMemberDetails):
                presentRoomMemberDetails(userID: userID)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .roomDetails):
                break
                
            case (.roomMemberDetails, .dismissUserProfile, .roomDetails):
                break
            
            case (.room, .presentResolveSendFailure(let failure, let sendHandle), .resolveSendFailure):
                presentResolveSendFailure(failure: failure, sendHandle: sendHandle)
            case (.resolveSendFailure, .dismissResolveSendFailure, .room):
                break
                
            case (.roomDetails, .presentKnockRequestsListScreen, .knockRequestsList):
                presentKnockRequestsList()
            case (.knockRequestsList, .dismissKnockRequestsListScreen, .roomDetails):
                break
            case (.room, .presentKnockRequestsListScreen, .knockRequestsList):
                presentKnockRequestsList()
            case (.knockRequestsList, .dismissKnockRequestsListScreen, .room):
                break
            
            case (.roomDetails, .presentMediaEventsTimeline, .mediaEventsTimeline):
                Task { await self.startMediaEventsTimelineFlow() }
            case (.mediaEventsTimeline, .dismissMediaEventsTimeline, .roomDetails):
                break
                
            case (.roomDetails, .presentSecurityAndPrivacyScreen, .securityAndPrivacy):
                presentSecurityAndPrivacyScreen()
            case (.securityAndPrivacy, .dismissSecurityAndPrivacyScreen, .roomDetails):
                break
                
            case (.roomDetails, .presentReportRoomScreen, .reportRoom):
                presentReportRoom()
            case (.reportRoom, .dismissReportRoomScreen, .roomDetails):
                break
                
            case (.joinRoomScreen, .presentDeclineAndBlockScreen(let userID), .declineAndBlockScreen):
                presentDeclineAndBlockScreen(userID: userID)
            case (.declineAndBlockScreen, .dismissDeclineAndBlockScreen, .joinRoomScreen):
                break
            
            // Child flow
            case (_, .startChildFlow(let roomID, let via, let entryPoint), .presentingChild):
                Task { await self.startChildFlow(for: roomID, via: via, entryPoint: entryPoint) }
            case (.presentingChild, .dismissChildFlow, _):
                childRoomFlowCoordinator = nil
            
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { context in
            if let event = context.event {
                MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                MXLog.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
        
        stateMachine.addErrorHandler { context in
            if context.fromState == context.toState {
                MXLog.error("Failed transition from equal states: \(context.fromState)")
            } else {
                fatalError("Failed transition with context: \(context)")
            }
        }
    }
    
    /// Updates the navigation stack so it displays the timeline for the given room
    /// - Parameters:
    ///   - fromState: The state that asked for the room presentation.
    ///   - focussedEvent: An (optional) struct that contains the event ID that the timeline should be focussed around, and a boolean telling if such event should update the pinned events banner
    ///   - animated: whether it should animate the transition
    private func presentRoom(fromState: State, presentationAction: PresentationAction?, animated: Bool) async {
        // If any sheets are presented dismiss them, rely on their dismissal callbacks to transition the state machine
        // through the correct states before presenting the room
        navigationStackCoordinator.setSheetCoordinator(nil)
        
        // Handle selecting the same room again
        if !isChildFlow {
            // First unwind the navigation stack
            navigationStackCoordinator.popToRoot(animated: animated)
            
            // And then decide if the room actually needs to be presented again
            switch fromState {
            case .initial, .roomDetails(isRoot: true), .joinRoomScreen:
                break
            default:
                // The room is already on the stack, no need to present it again
                
                switch presentationAction {
                case .eventFocus(let focusedEvent):
                    roomScreenCoordinator?.focusOnEvent(focusedEvent)
                case .share(.mediaFile(_, let mediaFile)):
                    stateMachine.tryEvent(.presentMediaUploadPreview(fileURL: mediaFile.url), userInfo: EventUserInfo(animated: animated))
                case .share(.text(_, let text)):
                    roomScreenCoordinator?.shareText(text)
                case .none:
                    break
                }
                
                return
            }
        }
        
        // Flag the room as read on entering, the timeline will take care of the read receipts
        Task { await roomProxy.flagAsUnread(false) }
        
        analytics.trackViewRoom(isDM: roomProxy.infoPublisher.value.isDirect, isSpace: roomProxy.infoPublisher.value.isSpace)
        
        let coordinator = makeRoomScreenCoordinator(presentationAction: presentationAction)
        roomScreenCoordinator = coordinator
        
        if !isChildFlow {
            let animated = UIDevice.current.userInterfaceIdiom == .phone ? animated : false
            navigationStackCoordinator.setRootCoordinator(coordinator, animated: animated) { [weak self] in
                self?.stateMachine.tryEvent(.dismissFlow)
            }
        } else {
            if joinRoomScreenCoordinator != nil {
                navigationStackCoordinator.pop()
            }
            
            navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
                self?.stateMachine.tryEvent(.dismissFlow)
            }
        }
            
        switch presentationAction {
        case .share(.mediaFile(_, let mediaFile)):
            stateMachine.tryEvent(.presentMediaUploadPreview(fileURL: mediaFile.url), userInfo: EventUserInfo(animated: animated))
        case .share(.text), .eventFocus:
            break // These are both handled in the coordinator's init.
        case .none:
            break
        }
    }
    
    private func makeRoomScreenCoordinator(presentationAction: PresentationAction?) -> RoomScreenCoordinator {
        let userID = userSession.clientProxy.userID
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
        let timelineController = timelineControllerFactory.buildTimelineController(roomProxy: roomProxy,
                                                                                   initialFocussedEventID: presentationAction?.focusedEvent?.eventID,
                                                                                   timelineItemFactory: timelineItemFactory,
                                                                                   mediaProvider: userSession.mediaProvider)
        self.timelineController = timelineController
        
        let completionSuggestionService = CompletionSuggestionService(roomProxy: roomProxy,
                                                                      roomListPublisher: userSession.clientProxy.staticRoomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        let composerDraftService = ComposerDraftService(roomProxy: roomProxy, timelineItemfactory: timelineItemFactory)
        
        let parameters = RoomScreenCoordinatorParameters(clientProxy: userSession.clientProxy,
                                                         roomProxy: roomProxy,
                                                         focussedEvent: presentationAction?.focusedEvent,
                                                         sharedText: presentationAction?.sharedText,
                                                         timelineController: timelineController,
                                                         mediaProvider: userSession.mediaProvider,
                                                         mediaPlayerProvider: MediaPlayerProvider(),
                                                         voiceMessageMediaManager: userSession.voiceMessageMediaManager,
                                                         emojiProvider: emojiProvider,
                                                         completionSuggestionService: completionSuggestionService,
                                                         ongoingCallRoomIDPublisher: ongoingCallRoomIDPublisher,
                                                         appMediator: appMediator,
                                                         appSettings: appSettings,
                                                         composerDraftService: composerDraftService,
                                                         timelineControllerFactory: timelineControllerFactory)
        
        let coordinator = RoomScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoomDetails:
                    stateMachine.tryEvent(.presentRoomDetails)
                case .presentReportContent(let itemID, let senderID):
                    stateMachine.tryEvent(.presentReportContent(itemID: itemID, senderID: senderID))
                case .presentMediaUploadPicker(let source):
                    stateMachine.tryEvent(.presentMediaUploadPicker(source: source))
                case .presentMediaUploadPreviewScreen(let url):
                    stateMachine.tryEvent(.presentMediaUploadPreview(fileURL: url))
                case .presentEmojiPicker(let itemID, let selectedEmojis):
                    stateMachine.tryEvent(.presentEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
                case .presentLocationPicker:
                    stateMachine.tryEvent(.presentMapNavigator(interactionMode: .picker))
                case .presentPollForm(let mode):
                    stateMachine.tryEvent(.presentPollForm(mode: mode))
                case .presentLocationViewer(_, let geoURI, let description):
                    stateMachine.tryEvent(.presentMapNavigator(interactionMode: .viewOnly(geoURI: geoURI, description: description)))
                case .presentRoomMemberDetails(userID: let userID):
                    stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID))
                case .presentMessageForwarding(let forwardingItem):
                    stateMachine.tryEvent(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .presentCallScreen:
                    actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
                case .presentPinnedEventsTimeline:
                    stateMachine.tryEvent(.presentPinnedEventsTimeline)
                case .presentResolveSendFailure(failure: let failure, sendHandle: let sendHandle):
                    stateMachine.tryEvent(.presentResolveSendFailure(failure: failure, sendHandle: sendHandle))
                case .presentKnockRequestsList:
                    stateMachine.tryEvent(.presentKnockRequestsListScreen)
                }
            }
            .store(in: &cancellables)
        
        return coordinator
    }
    
    private func presentJoinRoomScreen(via: [String], animated: Bool) {
        let coordinator = JoinRoomScreenCoordinator(parameters: .init(roomID: roomID,
                                                                      via: via,
                                                                      clientProxy: userSession.clientProxy,
                                                                      mediaProvider: userSession.mediaProvider,
                                                                      userIndicatorController: userIndicatorController,
                                                                      appSettings: appSettings))
        
        joinRoomScreenCoordinator = coordinator
        
        coordinator.actionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .joined:
                    Task { [weak self] in
                        guard let self else { return }
                        
                        if case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) {
                            await storeAndSubscribeToRoomProxy(roomProxy)
                            stateMachine.tryEvent(.presentRoom(presentationAction: nil), userInfo: EventUserInfo(animated: animated))
                            
                            analytics.trackJoinedRoom(isDM: roomProxy.infoPublisher.value.isDirect,
                                                      isSpace: roomProxy.infoPublisher.value.isSpace,
                                                      activeMemberCount: UInt(roomProxy.infoPublisher.value.activeMembersCount))
                        } else {
                            stateMachine.tryEvent(.dismissFlow, userInfo: EventUserInfo(animated: animated))
                        }
                    }
                case .cancelled:
                    stateMachine.tryEvent(.dismissJoinRoomScreen)
                case .presentDeclineAndBlock(let userID):
                    stateMachine.tryEvent(.presentDeclineAndBlockScreen(userID: userID))
                }
            }
            .store(in: &cancellables)
        
        if !isChildFlow {
            navigationStackCoordinator.setRootCoordinator(coordinator, animated: animated) { [weak self] in
                if self?.stateMachine.state == .joinRoomScreen {
                    self?.stateMachine.tryEvent(.dismissJoinRoomScreen)
                }
            }
        } else {
            navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
                if self?.stateMachine.state == .joinRoomScreen {
                    self?.stateMachine.tryEvent(.dismissJoinRoomScreen)
                }
            }
        }
    }
    
    private func dismissFlow(animated: Bool) {
        childRoomFlowCoordinator?.clearRoute(animated: animated)
        
        if isChildFlow {
            // We don't support dismissing a child flow by itself, only the entire chain.
            MXLog.info("Leaving the rest of the navigation clean-up to the parent flow.")
            
            if joinRoomScreenCoordinator != nil {
                navigationStackCoordinator.pop()
            }
        } else {
            navigationStackCoordinator.popToRoot(animated: false)
            navigationStackCoordinator.setRootCoordinator(nil, animated: false)
        }
        
        timelineController = nil
        
        actionsSubject.send(.finished)
        analytics.signpost.endRoomFlow()
    }
    
    private func presentRoomDetails(isRoot: Bool, animated: Bool) async {
        let params = RoomDetailsScreenCoordinatorParameters(roomProxy: roomProxy,
                                                            clientProxy: userSession.clientProxy,
                                                            mediaProvider: userSession.mediaProvider,
                                                            analyticsService: analytics,
                                                            userIndicatorController: userIndicatorController,
                                                            notificationSettings: userSession.clientProxy.notificationSettings,
                                                            attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                            appMediator: appMediator)
        let coordinator = RoomDetailsScreenCoordinator(parameters: params)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .leftRoom:
                stateMachine.tryEvent(.dismissFlow)
            case .presentRoomMembersList:
                stateMachine.tryEvent(.presentRoomMembersList)
            case .presentRoomDetailsEditScreen:
                stateMachine.tryEvent(.presentRoomDetailsEditScreen)
            case .presentNotificationSettingsScreen:
                stateMachine.tryEvent(.presentNotificationSettingsScreen)
            case .presentInviteUsersScreen:
                stateMachine.tryEvent(.presentInviteUsersScreen)
            case .presentPollsHistory:
                stateMachine.tryEvent(.presentPollsHistory)
            case .presentRolesAndPermissionsScreen:
                stateMachine.tryEvent(.presentRolesAndPermissionsScreen)
            case .presentCall:
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .presentPinnedEventsTimeline:
                stateMachine.tryEvent(.presentPinnedEventsTimeline)
            case .presentKnockingRequestsListScreen:
                stateMachine.tryEvent(.presentKnockRequestsListScreen)
            case .presentMediaEventsTimeline:
                stateMachine.tryEvent(.presentMediaEventsTimeline)
            case .presentSecurityAndPrivacyScreen:
                stateMachine.tryEvent(.presentSecurityAndPrivacyScreen)
            case .presentRecipientDetails(let userID):
                stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID))
            case .presentReportRoomScreen:
                stateMachine.tryEvent(.presentReportRoomScreen)
            }
        }
        .store(in: &cancellables)
        
        if isRoot {
            navigationStackCoordinator.setRootCoordinator(coordinator, animated: animated) { [weak self] in
                guard let self else { return }
                if stateMachine.state != .room { // The root has been replaced by a room
                    stateMachine.tryEvent(.dismissFlow)
                }
            }
        } else {
            navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
                guard let self else { return }
                if case .roomDetails = stateMachine.state {
                    stateMachine.tryEvent(.dismissRoomDetails)
                }
            }
        }
    }
    
    private func presentRoomMembersList() {
        let parameters = RoomMembersListScreenCoordinatorParameters(clientProxy: userSession.clientProxy,
                                                                    roomProxy: roomProxy,
                                                                    mediaProvider: userSession.mediaProvider,
                                                                    userIndicatorController: userIndicatorController,
                                                                    analytics: analytics)
        let coordinator = RoomMembersListScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .invite:
                    stateMachine.tryEvent(.presentInviteUsersScreen)
                case .selectedMember(let member):
                    stateMachine.tryEvent(.presentRoomMemberDetails(userID: member.userID))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomMembersList)
        }
    }
    
    private func presentKnockRequestsList() {
        let parameters = KnockRequestsListScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                      mediaProvider: userSession.mediaProvider,
                                                                      userIndicatorController: userIndicatorController)
        let coordinator = KnockRequestsListScreenCoordinator(parameters: parameters)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissKnockRequestsListScreen)
        }
    }
    
    private func presentRoomDetailsEditScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        
        let roomDetailsEditParameters = RoomDetailsEditScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                                   mediaProvider: userSession.mediaProvider,
                                                                                   mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: appSettings),
                                                                                   navigationStackCoordinator: stackCoordinator,
                                                                                   userIndicatorController: userIndicatorController,
                                                                                   orientationManager: appMediator.windowManager)
        let roomDetailsEditCoordinator = RoomDetailsEditScreenCoordinator(parameters: roomDetailsEditParameters)
        
        roomDetailsEditCoordinator.actions.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(roomDetailsEditCoordinator)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomDetailsEditScreen)
        }
    }
    
    private func presentReportContent(for itemID: TimelineItemIdentifier, from senderID: String) {
        guard let eventID = itemID.eventID else {
            fatalError()
        }
        
        let stackCoordinator = NavigationStackCoordinator()
        let parameters = ReportContentScreenCoordinatorParameters(eventID: eventID,
                                                                  senderID: senderID,
                                                                  roomProxy: roomProxy,
                                                                  clientProxy: userSession.clientProxy,
                                                                  userIndicatorController: userIndicatorController)
        let coordinator = ReportContentScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                navigationStackCoordinator.setSheetCoordinator(nil)
                
                switch action {
                case .cancel:
                    break
                case .finish:
                    userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonReportSubmitted, iconName: "checkmark"))
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissReportContent)
        }
    }
    
    private func presentMediaUploadPickerWithSource(_ source: MediaPickerScreenSource) {
        let stackCoordinator = NavigationStackCoordinator()

        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: userIndicatorController,
                                                                  source: source,
                                                                  orientationManager: appMediator.windowManager) { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .selectMediaAtURL(let url):
                stateMachine.tryEvent(.presentMediaUploadPreview(fileURL: url))
            }
        }

        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            if case .mediaUploadPicker = self?.stateMachine.state {
                self?.stateMachine.tryEvent(.dismissMediaUploadPicker)
            }
        }
    }

    private func presentMediaUploadPreviewScreen(for url: URL, animated: Bool) {
        let stackCoordinator = NavigationStackCoordinator()

        let parameters = MediaUploadPreviewScreenCoordinatorParameters(userIndicatorController: userIndicatorController,
                                                                       roomProxy: roomProxy,
                                                                       mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: appSettings),
                                                                       title: url.lastPathComponent,
                                                                       url: url,
                                                                       shouldShowCaptionWarning: appSettings.shouldShowMediaCaptionWarning)

        let mediaUploadPreviewScreenCoordinator = MediaUploadPreviewScreenCoordinator(parameters: parameters)
        
        mediaUploadPreviewScreenCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)

        stackCoordinator.setRootCoordinator(mediaUploadPreviewScreenCoordinator)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator, animated: animated) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMediaUploadPreview)
        }
    }
    
    private func presentEmojiPicker(for itemID: TimelineItemIdentifier, selectedEmoji: Set<String>) {
        let params = EmojiPickerScreenCoordinatorParameters(emojiProvider: emojiProvider,
                                                            itemID: itemID, selectedEmojis: selectedEmoji)
        let coordinator = EmojiPickerScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case let .emojiSelected(emoji: emoji, itemID: itemID):
                MXLog.debug("Selected \(emoji) for \(itemID)")
                navigationStackCoordinator.setSheetCoordinator(nil)
                Task {
                    guard case let .event(_, eventOrTransactionID) = itemID else {
                        fatalError()
                    }
                    
                    await self.timelineController?.toggleReaction(emoji, to: eventOrTransactionID)
                }
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissEmojiPicker)
        }
    }

    private func presentMapNavigator(interactionMode: StaticLocationInteractionMode) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let params = StaticLocationScreenCoordinatorParameters(interactionMode: interactionMode,
                                                               mapURLBuilder: appSettings.mapTilerConfiguration,
                                                               appMediator: appMediator)
        let coordinator = StaticLocationScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .selectedLocation(let geoURI, let isUserLocation):
                Task {
                    _ = await self.roomProxy.timeline.sendLocation(body: geoURI.bodyMessage,
                                                                   geoURI: geoURI,
                                                                   description: nil,
                                                                   zoomLevel: 15,
                                                                   assetType: isUserLocation ? .sender : .pin)
                    self.navigationStackCoordinator.setSheetCoordinator(nil)
                }
                
                self.analytics.trackComposer(inThread: false,
                                             isEditing: false,
                                             isReply: false,
                                             messageType: isUserLocation ? .LocationUser : .LocationPin,
                                             startsThread: nil)
            case .close:
                self.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMapNavigator)
        }
    }
    
    private func presentPollForm(mode: PollFormMode) {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = PollFormScreenCoordinator(parameters: .init(mode: mode))
        stackCoordinator.setRootCoordinator(coordinator)

        coordinator.actions
            .sink { [weak self] action in
                guard let self else {
                    return
                }

                self.navigationStackCoordinator.setSheetCoordinator(nil)

                switch action {
                case .cancel:
                    break
                case .delete:
                    deletePoll(mode: mode)
                case let .submit(question, options, pollKind):
                    switch mode {
                    case .new:
                        createPoll(question: question, options: options, pollKind: pollKind)
                    case .edit(let eventID, _):
                        editPoll(pollStartID: eventID, question: question, options: options, pollKind: pollKind)
                    }
                }
            }
            .store(in: &cancellables)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissPollForm)
        }
    }
    
    private func createPoll(question: String, options: [String], pollKind: Poll.Kind) {
        Task {
            let result = await roomProxy.timeline.createPoll(question: question, answers: options, pollKind: pollKind)

            self.analytics.trackComposer(inThread: false,
                                         isEditing: false,
                                         isReply: false,
                                         messageType: .Poll,
                                         startsThread: nil)

            self.analytics.trackPollCreated(isUndisclosed: pollKind == .undisclosed, numberOfAnswers: options.count)
            
            switch result {
            case .success:
                break
            case .failure:
                self.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            }
        }
    }
    
    private func editPoll(pollStartID: String, question: String, options: [String], pollKind: Poll.Kind) {
        Task {
            let result = await roomProxy.timeline.editPoll(original: pollStartID, question: question, answers: options, pollKind: pollKind)
            
            switch result {
            case .success:
                break
            case .failure:
                self.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            }
        }
    }
    
    private func deletePoll(mode: PollFormMode) {
        Task {
            guard case .edit(let pollStartID, _) = mode else {
                self.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
                return
            }
            
            let result = await roomProxy.redact(pollStartID)
            
            switch result {
            case .success:
                break
            case .failure:
                self.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            }
        }
    }
    
    private func presentPollsHistory() {
        Task {
            await asyncPresentRoomPollsHistory()
        }
    }
    
    private func asyncPresentRoomPollsHistory() async {
        let userID = userSession.clientProxy.userID
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
                
        let timelineController = timelineControllerFactory.buildTimelineController(roomProxy: roomProxy,
                                                                                   initialFocussedEventID: nil,
                                                                                   timelineItemFactory: timelineItemFactory,
                                                                                   mediaProvider: userSession.mediaProvider)
        
        let parameters = RoomPollsHistoryScreenCoordinatorParameters(pollInteractionHandler: PollInteractionHandler(analyticsService: analytics, roomProxy: roomProxy),
                                                                     timelineController: timelineController)
        let coordinator = RoomPollsHistoryScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .editPoll(let pollStartID, let poll):
                    stateMachine.tryEvent(.presentPollForm(mode: .edit(eventID: pollStartID, poll: poll)))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissPollsHistory)
        }
    }
    
    private func presentRoomMemberDetails(userID: String) {
        let params = RoomMemberDetailsScreenCoordinatorParameters(userID: userID,
                                                                  roomProxy: roomProxy,
                                                                  clientProxy: userSession.clientProxy,
                                                                  mediaProvider: userSession.mediaProvider,
                                                                  userIndicatorController: userIndicatorController,
                                                                  analytics: analytics)
        let coordinator = RoomMemberDetailsScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .openUserProfile:
                stateMachine.tryEvent(.presentUserProfile(userID: userID))
            case .openDirectChat(let roomID):
                stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: [], entryPoint: .room))
            case .startCall(let roomID):
                Task { await self.presentCallScreen(roomID: roomID) }
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomMemberDetails)
        }
    }
    
    private func replaceRoomMemberDetailsWithUserProfile(userID: String) {
        let parameters = UserProfileScreenCoordinatorParameters(userID: userID,
                                                                isPresentedModally: false,
                                                                clientProxy: userSession.clientProxy,
                                                                mediaProvider: userSession.mediaProvider,
                                                                userIndicatorController: userIndicatorController,
                                                                analytics: analytics)
        let coordinator = UserProfileScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: [], entryPoint: .room))
            case .startCall(let roomID):
                Task { await self.presentCallScreen(roomID: roomID) }
            case .dismiss:
                break // Not supported when pushed.
            }
        }
        .store(in: &cancellables)
        
        // Replace the RoomMemberDetailsScreen without any animation.
        // If this pop and push happens before the previous navigation is completed it might break screen presentation logic
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.navigationStackCoordinator.pop(animated: false)
            self.navigationStackCoordinator.push(coordinator, animated: false) { [weak self] in
                self?.stateMachine.tryEvent(.dismissUserProfile)
            }
        }
    }
    
    private func presentMessageForwarding(with forwardingItem: MessageForwardingItem) {
        let roomSummaryProvider = userSession.clientProxy.alternateRoomSummaryProvider
        
        let stackCoordinator = NavigationStackCoordinator()
        
        let parameters = MessageForwardingScreenCoordinatorParameters(forwardingItem: forwardingItem,
                                                                      clientProxy: userSession.clientProxy,
                                                                      roomSummaryProvider: roomSummaryProvider,
                                                                      mediaProvider: userSession.mediaProvider,
                                                                      userIndicatorController: userIndicatorController)
        let coordinator = MessageForwardingScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .sent(let roomID):
                navigationStackCoordinator.setSheetCoordinator(nil)
                // Timelines are cached - the local echo will be visible when fetching the room by its ID.
                stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: [], entryPoint: .room))
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMessageForwarding)
        }
    }
    
    private func presentNotificationSettingsScreen() {
        let parameters = RoomNotificationSettingsScreenCoordinatorParameters(notificationSettingsProxy: userSession.clientProxy.notificationSettings,
                                                                             roomProxy: roomProxy,
                                                                             displayAsUserDefinedRoomSettings: false)
        
        let coordinator = RoomNotificationSettingsScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] actions in
            switch actions {
            case .presentGlobalNotificationSettingsScreen:
                self?.stateMachine.tryEvent(.presentGlobalNotificationSettingsScreen)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissNotificationSettingsScreen)
        }
    }
    
    private func presentGlobalNotificationSettingsScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let parameters = NotificationSettingsScreenCoordinatorParameters(navigationStackCoordinator: stackCoordinator,
                                                                         userSession: userSession,
                                                                         userNotificationCenter: UNUserNotificationCenter.current(),
                                                                         notificationSettings: userSession.clientProxy.notificationSettings,
                                                                         isModallyPresented: true)
        let coordinator = NotificationSettingsScreenCoordinator(parameters: parameters)
        coordinator.actions.sink { [weak self] action in
            switch action {
            case .close:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissGlobalNotificationSettingsScreen)
        }
    }
    
    private func presentInviteUsersScreen() {
        let selectedUsersSubject: CurrentValueSubject<[UserProfileProxy], Never> = .init([])
        
        let stackCoordinator = NavigationStackCoordinator()
        let inviteParameters = InviteUsersScreenCoordinatorParameters(clientProxy: userSession.clientProxy,
                                                                      selectedUsers: .init(selectedUsersSubject),
                                                                      roomType: .room(roomProxy: roomProxy),
                                                                      mediaProvider: userSession.mediaProvider,
                                                                      userDiscoveryService: UserDiscoveryService(clientProxy: userSession.clientProxy),
                                                                      userIndicatorController: userIndicatorController)
        
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        stackCoordinator.setRootCoordinator(coordinator)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .proceed:
                break
            case .invite(let users):
                self.inviteUsers(users, in: roomProxy)
            case .toggleUser(let user):
                var selectedUsers = selectedUsersSubject.value
                
                if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                    selectedUsers.remove(at: index)
                } else {
                    selectedUsers.append(user)
                }
                
                selectedUsersSubject.send(selectedUsers)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissInviteUsersScreen)
        }
    }
    
    private func inviteUsers(_ users: [String], in room: JoinedRoomProxyProtocol) {
        navigationStackCoordinator.setSheetCoordinator(nil)
        
        Task {
            let result: Result<Void, RoomProxyError> = await withTaskGroup(of: Result<Void, RoomProxyError>.self) { group in
                for user in users {
                    group.addTask {
                        await room.invite(userID: user)
                    }
                }
                
                return await group.first { inviteResult in
                    inviteResult.isFailure
                } ?? .success(())
            }
            
            guard case .failure = result else {
                return
            }
            
            userIndicatorController.alertInfo = .init(id: .init(),
                                                      title: L10n.commonUnableToInviteTitle,
                                                      message: L10n.commonUnableToInviteMessage)
        }
    }
    
    private func presentRolesAndPermissionsScreen() {
        let parameters = RoomRolesAndPermissionsFlowCoordinatorParameters(roomProxy: roomProxy,
                                                                          mediaProvider: userSession.mediaProvider,
                                                                          navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: userIndicatorController,
                                                                          analytics: analytics)
        let coordinator = RoomRolesAndPermissionsFlowCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.stateMachine.tryEvent(.dismissRolesAndPermissionsScreen)
            }
        }
        .store(in: &cancellables)
        
        rolesAndPermissionsFlowCoordinator = coordinator
        coordinator.start()
    }
    
    private func presentResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, sendHandle: SendHandleProxy) {
        let coordinator = ResolveVerifiedUserSendFailureScreenCoordinator(parameters: .init(failure: failure,
                                                                                            sendHandle: sendHandle,
                                                                                            roomProxy: roomProxy,
                                                                                            userIndicatorController: userIndicatorController))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissResolveSendFailure)
        }
    }
    
    private func presentSecurityAndPrivacyScreen() {
        let coordinator = SecurityAndPrivacyScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                                clientProxy: userSession.clientProxy,
                                                                                userIndicatorController: userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .displayEditAddressScreen:
                presentEditAddressScreen()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissSecurityAndPrivacyScreen)
        }
    }
    
    private func presentEditAddressScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = EditRoomAddressScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                             clientProxy: userSession.clientProxy,
                                                                             userIndicatorController: userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator)
    }
    
    private func presentReportRoom() {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = ReportRoomScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                        userIndicatorController: userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss(let shouldLeaveRoom):
                if shouldLeaveRoom {
                    stateMachine.tryEvent(.dismissFlow)
                }
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissReportRoomScreen)
        }
    }
    
    private func presentDeclineAndBlockScreen(userID: String) {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = DeclineAndBlockScreenCoordinator(parameters: .init(userID: userID,
                                                                             roomID: roomID,
                                                                             clientProxy: userSession.clientProxy,
                                                                             userIndicatorController: userIndicatorController))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss(let hasDeclined):
                if hasDeclined {
                    stateMachine.tryEvent(.dismissFlow)
                }
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissDeclineAndBlockScreen)
        }
    }
    
    // MARK: - Other flows
    
    private func startChildFlow(for roomID: String, via: [String], entryPoint: RoomFlowCoordinatorEntryPoint) async {
        let coordinator = await RoomFlowCoordinator(roomID: roomID,
                                                    userSession: userSession,
                                                    isChildFlow: true,
                                                    timelineControllerFactory: timelineControllerFactory,
                                                    navigationStackCoordinator: navigationStackCoordinator,
                                                    emojiProvider: emojiProvider,
                                                    ongoingCallRoomIDPublisher: ongoingCallRoomIDPublisher,
                                                    appMediator: appMediator,
                                                    appSettings: appSettings,
                                                    analytics: analytics,
                                                    userIndicatorController: userIndicatorController)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            case .finished:
                stateMachine.tryEvent(.dismissChildFlow)
            }
        }
        .store(in: &cancellables)
        
        childRoomFlowCoordinator = coordinator
        switch entryPoint {
        case .room:
            coordinator.handleAppRoute(.room(roomID: roomID, via: via), animated: true)
        case .eventID(let eventID):
            coordinator.handleAppRoute(.event(eventID: eventID, roomID: roomID, via: via), animated: true)
        case .roomDetails:
            coordinator.handleAppRoute(.roomDetails(roomID: roomID), animated: true)
        case .share(let payload):
            coordinator.handleAppRoute(.share(payload), animated: true)
        }
    }
    
    private func startPinnedEventsTimelineFlow() {
        let stackCoordinator = NavigationStackCoordinator()
        
        let flowCoordinator = PinnedEventsTimelineFlowCoordinator(navigationStackCoordinator: stackCoordinator,
                                                                  userSession: userSession,
                                                                  timelineControllerFactory: timelineControllerFactory,
                                                                  roomProxy: roomProxy,
                                                                  userIndicatorController: userIndicatorController,
                                                                  appSettings: appSettings,
                                                                  appMediator: appMediator,
                                                                  emojiProvider: emojiProvider)
        
        flowCoordinator.actionsPublisher.sink { [weak self] action in
            guard let self else {
                return
            }
            
            switch action {
            case .finished:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .displayUser(let userID):
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.presentRoomMemberDetails(userID: userID))
            case .forwardedMessageToRoom(let roomID):
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: [], entryPoint: .room))
            case .displayRoomScreenWithFocussedPin(let eventID):
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.presentRoom(presentationAction: .eventFocus(.init(eventID: eventID, shouldSetPin: true))))
            }
        }
        .store(in: &cancellables)
        
        pinnedEventsTimelineFlowCoordinator = flowCoordinator
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissPinnedEventsTimeline)
        }
        
        flowCoordinator.start()
    }
    
    private func startMediaEventsTimelineFlow() async {
        let flowCoordinator = MediaEventsTimelineFlowCoordinator(navigationStackCoordinator: navigationStackCoordinator,
                                                                 userSession: userSession,
                                                                 timelineControllerFactory: timelineControllerFactory,
                                                                 roomProxy: roomProxy,
                                                                 userIndicatorController: userIndicatorController,
                                                                 appMediator: appMediator,
                                                                 emojiProvider: emojiProvider)
        
        flowCoordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .viewInRoomTimeline(let itemID):
                guard let eventID = itemID.eventID else {
                    MXLog.error("Unable to present room timeline for event \(itemID)")
                    return
                }
                stateMachine.tryEvent(.presentRoom(presentationAction: .eventFocus(.init(eventID: eventID, shouldSetPin: false))),
                                      userInfo: EventUserInfo(animated: false)) // No animation so the timeline visible when the preview animates away.
            case .finished:
                stateMachine.tryEvent(.dismissMediaEventsTimeline)
            }
        }
        .store(in: &cancellables)
        
        mediaEventsTimelineFlowCoordinator = flowCoordinator
        
        flowCoordinator.start()
    }
    
    private static let loadingIndicatorID = "\(RoomFlowCoordinator.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil) {
        userIndicatorController.submitIndicator(.init(id: Self.loadingIndicatorID,
                                                      type: .modal(progress: .indeterminate,
                                                                   interactiveDismissDisabled: false,
                                                                   allowsInteraction: false),
                                                      title: L10n.commonLoading, persistent: true),
                                                delay: delay)
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
}

private extension RoomFlowCoordinator {
    struct HashableRoomMemberWrapper: Hashable {
        let value: RoomMemberProxyProtocol

        static func == (lhs: HashableRoomMemberWrapper, rhs: HashableRoomMemberWrapper) -> Bool {
            lhs.value.userID == rhs.value.userID
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(value.userID)
        }
    }

    indirect enum State: StateType {
        case initial
        case joinRoomScreen
        case room
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
}
