//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState
import SwiftUI
import UserNotifications

enum RoomFlowCoordinatorAction: Equatable {
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
    /// The requested room was actually a space. The room flow has been dismissed
    /// and a space flow should be started to continue.
    case continueWithSpaceFlow(SpaceRoomListProxyProtocol)
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
    /// The flow will start by showing a thread timeline, can only be triggered by notification taps,
    /// which means it can never be a used for child flows.
    case thread(rootEventID: String, focusEventID: String?)
    /// The flow will start by showing the room's details.
    case roomDetails
    /// An external media share request
    case share(ShareExtensionPayload)
    /// The flow to change the the owner of the room
    case transferOwnership
    
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

// swiftlint:disable:next type_body_length
class RoomFlowCoordinator: FlowCoordinatorProtocol {
    private let roomID: String
    private let isChildFlow: Bool
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    
    private var userSession: UserSessionProtocol { flowParameters.userSession }
    
    private var roomProxy: JoinedRoomProxyProtocol!
    
    private var roomScreenCoordinator: RoomScreenCoordinator?
    private var childThreadScreenCoordinators: [ThreadTimelineScreenCoordinator] = []
    private weak var joinRoomScreenCoordinator: JoinRoomScreenCoordinator?
    
    // periphery:ignore - used to avoid deallocation
    private var rolesAndPermissionsFlowCoordinator: RoomRolesAndPermissionsFlowCoordinator?
    // periphery:ignore - used to avoid deallocation
    private var pinnedEventsTimelineFlowCoordinator: PinnedEventsTimelineFlowCoordinator?
    // periphery:ignore - used to avoid deallocation
    private var mediaEventsTimelineFlowCoordinator: MediaEventsTimelineFlowCoordinator?
    // periphery:ignore - used to avoid deallocation
    private var childRoomFlowCoordinator: RoomFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var spaceFlowCoordinator: SpaceFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var membersFlowCoordinator: RoomMembersFlowCoordinator?
    
    private let stateMachine: StateMachine<State, Event> = .init(state: .initial)
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var timelineController: TimelineControllerProtocol?
    
    init(roomID: String,
         isChildFlow: Bool,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.roomID = roomID
        self.isChildFlow = isChildFlow
        self.navigationStackCoordinator = navigationStackCoordinator
        self.flowParameters = flowParameters
        
        setupStateMachine()
        
        flowParameters.analytics.signpost.beginRoomFlow(roomID)
    }
        
    // MARK: - FlowCoordinatorProtocol
    
    func start(animated: Bool) {
        fatalError("This flow coordinator expect a route")
    }
    
    // swiftlint:disable:next cyclomatic_complexity
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
            if case .membersFlow = stateMachine.state, let membersFlowCoordinator {
                membersFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else if case .presentingChild = stateMachine.state, let childRoomFlowCoordinator {
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
            if case .membersFlow = stateMachine.state, let membersFlowCoordinator {
                membersFlowCoordinator.handleAppRoute(.roomMemberDetails(userID: userID), animated: animated)
            } else if case .presentingChild = stateMachine.state, let childRoomFlowCoordinator {
                childRoomFlowCoordinator.handleAppRoute(appRoute, animated: animated)
            } else {
                stateMachine.tryEvent(.startMembersFlow(entryPoint: .roomMember(userID: userID)), userInfo: EventUserInfo(animated: animated))
            }
        case .thread(let roomID, let threadRootEventID, let focusEventID):
            Task {
                await handleRoomRoute(roomID: roomID,
                                      via: [],
                                      presentationAction: .thread(rootEventID: threadRootEventID,
                                                                  focusEventID: focusEventID),
                                      animated: animated)
            }
        case .event(let eventID, let roomID, let via):
            Task {
                await handleRoomRoute(roomID: roomID,
                                      via: via,
                                      presentationAction: .eventFocus(.init(eventID: eventID, shouldSetPin: false)),
                                      animated: animated)
            }
        case .childEvent(let eventID, let roomID, let via):
            handleChildEventRoute(eventID: eventID, roomID: roomID, via: via, animated: animated)
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
        case .accountProvisioningLink, .roomList, .userProfile, .call, .genericCallLink, .settings, .chatBackupSettings:
            break // These routes can't be handled.
        case .transferOwnership(let roomID):
            guard self.roomID == roomID else { fatalError("Navigation route doesn't belong to this room flow.") }
            
            Task {
                if roomProxy == nil {
                    guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
                        return
                    }
                    
                    await storeAndSubscribeToRoomProxy(roomProxy)
                }
                
                presentTransferOwnershipScreen()
            }
        }
    }
    
    private func handleChildEventRoute(eventID: String, roomID: String, via: [String], animated: Bool) {
        if case .membersFlow = stateMachine.state, let membersFlowCoordinator {
            membersFlowCoordinator.handleAppRoute(.childEvent(eventID: eventID, roomID: roomID, via: via), animated: animated)
        } else if case .presentingChild = stateMachine.state, let childRoomFlowCoordinator {
            childRoomFlowCoordinator.handleAppRoute(.childEvent(eventID: eventID, roomID: roomID, via: via), animated: animated)
        } else if roomID != roomProxy.id {
            stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: via, entryPoint: .eventID(eventID)), userInfo: EventUserInfo(animated: animated))
        } else {
            showLoadingIndicator(delay: .seconds(0.5))
            Task {
                defer { hideLoadingIndicator() }
                switch await roomProxy.loadOrFetchEventDetails(for: eventID) {
                case .success(let event):
                    if flowParameters.appSettings.threadsEnabled, let threadRootEventID = event.threadRootEventId() {
                        if case .thread(threadRootEventID: threadRootEventID, _) = stateMachine.state, let threadCoordinator = childThreadScreenCoordinators.last {
                            threadCoordinator.focusOnEvent(eventID: eventID)
                        } else {
                            // If we are showing the room timeline, we want to focus the thread root.
                            if childThreadScreenCoordinators.isEmpty {
                                roomScreenCoordinator?.focusOnEvent(.init(eventID: threadRootEventID, shouldSetPin: false))
                            }
                            stateMachine.tryEvent(.presentThread(threadRootEventID: threadRootEventID, focusEventID: eventID))
                        }
                    } else if !childThreadScreenCoordinators.isEmpty {
                        // If we are showing a child thread and we are navigating to a non threaded event
                        // of the same room, we want to push the room on top of the thread.
                        stateMachine.tryEvent(.startChildFlow(roomID: roomID, via: via, entryPoint: .eventID(eventID)), userInfo: EventUserInfo(animated: animated))
                    } else {
                        roomScreenCoordinator?.focusOnEvent(.init(eventID: eventID, shouldSetPin: false))
                    }
                case .failure:
                    showErrorIndicator()
                }
            }
        }
    }
    
    private func presentTransferOwnershipScreen() {
        let parameters = RoomChangeRolesScreenCoordinatorParameters(mode: .owner,
                                                                    roomProxy: roomProxy,
                                                                    mediaProvider: userSession.mediaProvider,
                                                                    userIndicatorController: flowParameters.userIndicatorController,
                                                                    analytics: flowParameters.analytics)
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = RoomChangeRolesScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator, animated: true)
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
            if roomProxy.infoPublisher.value.isSpace {
                switch await userSession.clientProxy.spaceService.spaceRoomList(spaceID: roomProxy.id) {
                case .success(let spaceRoomListProxy):
                    actionsSubject.send(.continueWithSpaceFlow(spaceRoomListProxy))
                case .failure:
                    showErrorIndicator()
                    stateMachine.tryEvent(.dismissFlow)
                }
            } else {
                await storeAndSubscribeToRoomProxy(roomProxy)
                
                guard case let .eventFocus(focusEvent) = presentationAction else {
                    // If is not a focus event just handle the presentation action directly in `presentRoom`
                    stateMachine.tryEvent(.presentRoom(presentationAction: presentationAction), userInfo: EventUserInfo(animated: animated))
                    return
                }
                
                // Otherwise check if the focussed event exists to handle a possible error or theaded event.
                switch await roomProxy.loadOrFetchEventDetails(for: focusEvent.eventID) {
                case .success(let event):
                    if flowParameters.appSettings.threadsEnabled, let threadRootEventID = event.threadRootEventId() {
                        stateMachine.tryEvent(.presentRoom(presentationAction: .thread(rootEventID: threadRootEventID, focusEventID: focusEvent.eventID)), userInfo: EventUserInfo(animated: animated))
                    } else {
                        stateMachine.tryEvent(.presentRoom(presentationAction: presentationAction), userInfo: EventUserInfo(animated: animated))
                    }
                case .failure:
                    showErrorIndicator()
                    stateMachine.tryEvent(.presentRoom(presentationAction: nil), userInfo: EventUserInfo(animated: animated))
                }
            }
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
        
        // Subscribe to room info updates in order to detect rooms being left on other devices
        // and react accordingly by dismissing this flow coordinator.
        self.roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self else { return }
                
                if info.membership == .left || info.membership == .banned, stateMachine.state != .complete {
                    stateMachine.tryEvent(.dismissFlow)
                }
            }
            .store(in: &cancellables)
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func setupStateMachine() {
        addRouteMapping(stateMachine: stateMachine)
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            let animated = (context.userInfo as? EventUserInfo)?.animated ?? true
            
            switch (context.fromState, context.event, context.toState) {
            // Room
                
            case (_, .presentRoom(let presentationAction), .room):
                Task {
                    await self.presentRoom(fromState: context.fromState,
                                           presentationAction: presentationAction,
                                           animated: animated)
                }
            case (_, .dismissFlow, .complete):
                dismissFlow(animated: animated)
                    
            case (.room, .presentPinnedEventsTimeline, .pinnedEventsTimeline):
                startPinnedEventsTimelineFlow()
                
            // Thread
                
            case (_, .presentThread(let threadRootEventID, let focusEventID), .thread):
                Task { await self.presentThread(threadRootEventID: threadRootEventID, focusEventID: focusEventID, animated: animated) }
                
            // Thread + Room
                
            case (_, .startSpaceFlow, .spaceFlow):
                guard let spaceRoomListProxy = (context.userInfo as? EventUserInfo)?.spaceRoomListProxy else {
                    fatalError("The space room list proxy is required to present a space.")
                }
                startSpaceFlow(spaceRoomListProxy: spaceRoomListProxy, animated: animated)
            case (.spaceFlow, .finishedSpaceFlow, _):
                spaceFlowCoordinator = nil
                
            case (_, .presentReportContent, .reportContent(let itemID, let senderID, _)):
                presentReportContent(for: itemID, from: senderID)
                
            case (_, .presentMediaUploadPicker, .mediaUploadPicker(let mode, _)):
                guard let timelineController = (context.userInfo as? EventUserInfo)?.timelineController else {
                    fatalError("Missing required TimelineController")
                }
                presentMediaUploadPickerWithMode(mode, timelineController: timelineController, animated: animated)
                
            case (_, .presentEmojiPicker, .emojiPicker(let itemID, let selectedEmoji, _)):
                guard let timelineController = (context.userInfo as? EventUserInfo)?.timelineController else {
                    fatalError("Missing required TimelineController")
                }
                presentEmojiPicker(for: itemID,
                                   selectedEmoji: selectedEmoji,
                                   timelineController: timelineController,
                                   animated: animated)
                
            case (_, .presentMessageForwarding(let forwardingItem), .messageForwarding):
                presentMessageForwarding(with: forwardingItem)

            case (_, .presentMapNavigator(let mode), .mapNavigator):
                guard let timelineController = (context.userInfo as? EventUserInfo)?.timelineController else {
                    fatalError("Missing required TimelineController")
                }
                presentMapNavigator(interactionMode: mode, timelineController: timelineController, animated: animated)

            case (_, .presentPollForm(let mode), .pollForm):
                guard let timelineController = (context.userInfo as? EventUserInfo)?.timelineController else {
                    fatalError("Missing required TimelineController")
                }
                presentPollForm(mode: mode, timelineController: timelineController)
                
            case (_, .presentResolveSendFailure(let failure, let sendHandle), .resolveSendFailure):
                presentResolveSendFailure(failure: failure, sendHandle: sendHandle)
                
            // Room Details
            
            case (.initial, .presentRoomDetails, .roomDetails(let isRoot)),
                 (.room, .presentRoomDetails, .roomDetails(let isRoot)),
                 (.roomDetails, .presentRoomDetails, .roomDetails(let isRoot)):
                Task { await self.presentRoomDetails(isRoot: isRoot, animated: animated) }
                
            case (.roomDetails, .presentRoomDetailsEditScreen, .roomDetailsEditScreen):
                presentRoomDetailsEditScreen()
                
            case (.roomDetails, .presentNotificationSettingsScreen, .notificationSettings):
                presentNotificationSettingsScreen()
                
            case (.roomDetails, .presentPollsHistory, .pollsHistory):
                Task { await self.presentRoomPollsHistory(animated: animated) }
                
            case (.roomDetails, .presentPinnedEventsTimeline, .pinnedEventsTimeline):
                startPinnedEventsTimelineFlow()
                
            case (.roomDetails, .presentRolesAndPermissionsScreen, .rolesAndPermissions):
                presentRolesAndPermissionsScreen()
            case (.rolesAndPermissions, .dismissRolesAndPermissionsScreen, .roomDetails):
                rolesAndPermissionsFlowCoordinator = nil
                                            
            case (.roomDetails, .presentMediaEventsTimeline, .mediaEventsTimeline):
                Task { await self.startMediaEventsTimelineFlow() }
                
            case (.roomDetails, .presentSecurityAndPrivacyScreen, .securityAndPrivacy):
                presentSecurityAndPrivacyScreen()
                
            case (.roomDetails, .presentReportRoomScreen, .reportRoom):
                presentReportRoom()
                
            // Join room
                
            case (_, .presentJoinRoomScreen(let via), .joinRoomScreen):
                presentJoinRoomScreen(via: via, animated: true)
            case (_, .dismissJoinRoomScreen, .complete):
                dismissFlow(animated: animated)
            case (_, .joinedSpace, .complete):
                guard let spaceRoomListProxy = (context.userInfo as? EventUserInfo)?.spaceRoomListProxy else {
                    fatalError("The space room list proxy is required to present a space.")
                }
                dismissFlow(animated: animated, continuingWith: spaceRoomListProxy)
                
            case (.joinRoomScreen, .presentDeclineAndBlockScreen(let userID), .declineAndBlockScreen):
                presentDeclineAndBlockScreen(userID: userID)
                
            // Other
                
            case (_, .startMembersFlow(let entryPoint), .membersFlow):
                startMembersFlow(entryPoint: entryPoint, animated: animated)
            case (.membersFlow, .stopMembersFlow, _):
                membersFlowCoordinator = nil
                                    
            case (_, .startChildFlow(let roomID, let via, let entryPoint), .presentingChild):
                startChildFlow(for: roomID, via: via, entryPoint: entryPoint)
            case (.presentingChild, .dismissChildFlow, _):
                childRoomFlowCoordinator = nil
                
            case (_, .presentKnockRequestsListScreen, .knockRequestsList):
                presentKnockRequestsList()
                
            case (.notificationSettings, .presentGlobalNotificationSettingsScreen, .globalNotificationSettings):
                presentGlobalNotificationSettingsScreen()
                    
            case (.pollsHistory, .presentPollForm(let mode), .pollsHistoryForm):
                guard let timelineController = (context.userInfo as? EventUserInfo)?.timelineController else {
                    fatalError("Missing required TimelineController")
                }
                presentPollForm(mode: mode, timelineController: timelineController)
                
            case (_, .presentMediaUploadPreview, .mediaUploadPreview(let mediaURLs, _)):
                guard let timelineController = (context.userInfo as? EventUserInfo)?.timelineController else {
                    fatalError("Missing required TimelineController")
                }
                
                presentMediaUploadPreviewScreen(for: mediaURLs, timelineController: timelineController, animated: animated)
                
            case (_, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
                    
            default:
                break
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
    ///   - presentationAction: The action that should happen after the room is presented
    ///   - animated: whether it should animate the transition
    private func presentRoom(fromState: State,
                             presentationAction: PresentationAction?,
                             animated: Bool) async {
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
                case .share(.mediaFiles(_, let mediaFiles)):
                    stateMachine.tryEvent(.presentMediaUploadPreview(mediaURLs: mediaFiles.map(\.url)),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .share(.text(_, let text)):
                    roomScreenCoordinator?.shareText(text)
                case .thread(let rootEventID, let focusEventID):
                    roomScreenCoordinator?.focusOnEvent(.init(eventID: rootEventID, shouldSetPin: false))
                    stateMachine.tryEvent(.presentThread(threadRootEventID: rootEventID, focusEventID: focusEventID))
                case .none:
                    break
                }
                
                return
            }
        }
        
        // Flag the room as read on entering, the timeline will take care of the read receipts
        Task { await roomProxy.flagAsUnread(false) }
        
        flowParameters.analytics.trackViewRoom(isDM: roomProxy.infoPublisher.value.isDirect, isSpace: roomProxy.infoPublisher.value.isSpace)
        
        let coordinator = makeRoomScreenCoordinator(presentationAction: presentationAction, animated: animated)
        roomScreenCoordinator = coordinator
        
        if !isChildFlow {
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
        case .share(.mediaFiles(_, let mediaFiles)):
            stateMachine.tryEvent(.presentMediaUploadPreview(mediaURLs: mediaFiles.map(\.url)),
                                  userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
        case .thread(let rootEventID, let focusEventID):
            stateMachine.tryEvent(.presentThread(threadRootEventID: rootEventID, focusEventID: focusEventID))
        case .share(.text), .eventFocus:
            break // These are both handled in the coordinator's init.
        case .none:
            break
        }
    }
    
    private func makeRoomScreenCoordinator(presentationAction: PresentationAction?, animated: Bool) -> RoomScreenCoordinator {
        let userID = userSession.clientProxy.userID
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
        let timelineController = flowParameters.timelineControllerFactory.buildTimelineController(roomProxy: roomProxy,
                                                                                                  initialFocussedEventID: presentationAction?.focusedEvent?.eventID,
                                                                                                  timelineItemFactory: timelineItemFactory,
                                                                                                  mediaProvider: userSession.mediaProvider)
        self.timelineController = timelineController
        
        let completionSuggestionService = CompletionSuggestionService(roomProxy: roomProxy,
                                                                      roomListPublisher: userSession.clientProxy.staticRoomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        let composerDraftService = ComposerDraftService(roomProxy: roomProxy,
                                                        timelineItemfactory: timelineItemFactory,
                                                        threadRootEventID: nil)
        
        let parameters = RoomScreenCoordinatorParameters(userSession: userSession,
                                                         roomProxy: roomProxy,
                                                         focussedEvent: presentationAction?.focusedEvent,
                                                         sharedText: presentationAction?.sharedText,
                                                         timelineController: timelineController,
                                                         mediaPlayerProvider: MediaPlayerProvider(),
                                                         emojiProvider: flowParameters.emojiProvider,
                                                         linkMetadataProvider: flowParameters.linkMetadataProvider,
                                                         completionSuggestionService: completionSuggestionService,
                                                         ongoingCallRoomIDPublisher: flowParameters.ongoingCallRoomIDPublisher,
                                                         appMediator: flowParameters.appMediator,
                                                         appSettings: flowParameters.appSettings,
                                                         appHooks: flowParameters.appHooks,
                                                         analytics: flowParameters.analytics,
                                                         composerDraftService: composerDraftService,
                                                         timelineControllerFactory: flowParameters.timelineControllerFactory,
                                                         userIndicatorController: flowParameters.userIndicatorController)
        
        let coordinator = RoomScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoomDetails:
                    stateMachine.tryEvent(.presentRoomDetails)
                case .presentReportContent(let itemID, let senderID):
                    stateMachine.tryEvent(.presentReportContent(itemID: itemID,
                                                                senderID: senderID))
                case .presentMediaUploadPicker(let mode):
                    stateMachine.tryEvent(.presentMediaUploadPicker(mode: mode),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .presentMediaUploadPreviewScreen(let url):
                    stateMachine.tryEvent(.presentMediaUploadPreview(mediaURLs: url),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .presentEmojiPicker(let itemID, let selectedEmojis):
                    stateMachine.tryEvent(.presentEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .presentLocationPicker:
                    stateMachine.tryEvent(.presentMapNavigator(interactionMode: .picker),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .presentPollForm(let mode):
                    stateMachine.tryEvent(.presentPollForm(mode: mode),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .presentLocationViewer(_, let geoURI, let description):
                    stateMachine.tryEvent(.presentMapNavigator(interactionMode: .viewOnly(geoURI: geoURI, description: description)),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                case .presentRoomMemberDetails(userID: let userID):
                    stateMachine.tryEvent(.startMembersFlow(entryPoint: .roomMember(userID: userID)))
                case .presentMessageForwarding(let forwardingItem):
                    stateMachine.tryEvent(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .presentCallScreen:
                    actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
                case .presentPinnedEventsTimeline:
                    stateMachine.tryEvent(.presentPinnedEventsTimeline)
                case .presentResolveSendFailure(failure: let failure, sendHandle: let sendHandle):
                    stateMachine.tryEvent(.presentResolveSendFailure(failure: failure,
                                                                     sendHandle: sendHandle))
                case .presentKnockRequestsList:
                    stateMachine.tryEvent(.presentKnockRequestsListScreen)
                case .presentThread(let itemID):
                    guard let threadRootEventID = itemID.eventID else {
                        fatalError("A thread root has always an eventID")
                    }
                    stateMachine.tryEvent(.presentThread(threadRootEventID: threadRootEventID, focusEventID: nil))
                case .presentRoom(let roomID, let via):
                    stateMachine.tryEvent(.startChildFlow(roomID: roomID,
                                                          via: via,
                                                          entryPoint: .room))
                }
            }
            .store(in: &cancellables)
        
        return coordinator
    }
    
    private func presentThread(threadRootEventID: String, focusEventID: String?, animated: Bool) async {
        showLoadingIndicator()
        defer { hideLoadingIndicator() }
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userSession.clientProxy.userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userSession.clientProxy.userID))
        
        guard case let .success(timelineController) = await flowParameters.timelineControllerFactory.buildThreadTimelineController(threadRootEventID: threadRootEventID,
                                                                                                                                   initialFocussedEventID: focusEventID,
                                                                                                                                   roomProxy: roomProxy,
                                                                                                                                   timelineItemFactory: timelineItemFactory,
                                                                                                                                   mediaProvider: userSession.mediaProvider) else {
            MXLog.error("Failed presenting media timeline")
            return
        }
        
        let completionSuggestionService = CompletionSuggestionService(roomProxy: roomProxy,
                                                                      roomListPublisher: userSession.clientProxy.staticRoomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        let composerDraftService = ComposerDraftService(roomProxy: roomProxy,
                                                        timelineItemfactory: timelineItemFactory,
                                                        threadRootEventID: threadRootEventID)
        
        let coordinator = ThreadTimelineScreenCoordinator(parameters: .init(userSession: userSession,
                                                                            roomProxy: roomProxy,
                                                                            focussedEventID: focusEventID,
                                                                            timelineController: timelineController,
                                                                            mediaPlayerProvider: MediaPlayerProvider(),
                                                                            emojiProvider: flowParameters.emojiProvider,
                                                                            linkMetadataProvider: flowParameters.linkMetadataProvider,
                                                                            completionSuggestionService: completionSuggestionService,
                                                                            appMediator: flowParameters.appMediator,
                                                                            appSettings: flowParameters.appSettings,
                                                                            analytics: flowParameters.analytics,
                                                                            composerDraftService: composerDraftService,
                                                                            timelineControllerFactory: flowParameters.timelineControllerFactory,
                                                                            userIndicatorController: flowParameters.userIndicatorController))
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .presentReportContent(let itemID, let senderID):
                stateMachine.tryEvent(.presentReportContent(itemID: itemID, senderID: senderID))
            case .presentMediaUploadPicker(let mode):
                stateMachine.tryEvent(.presentMediaUploadPicker(mode: mode),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            case .presentMediaUploadPreviewScreen(let mediaURLs):
                stateMachine.tryEvent(.presentMediaUploadPreview(mediaURLs: mediaURLs),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            case .presentLocationPicker:
                stateMachine.tryEvent(.presentMapNavigator(interactionMode: .picker),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            case .presentPollForm(let mode):
                stateMachine.tryEvent(.presentPollForm(mode: mode),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            case .presentLocationViewer(_, let geoURI, let description):
                stateMachine.tryEvent(.presentMapNavigator(interactionMode: .viewOnly(geoURI: geoURI,
                                                                                      description: description)),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            case .presentEmojiPicker(let itemID, let selectedEmojis):
                stateMachine.tryEvent(.presentEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            case .presentRoomMemberDetails(let userID):
                stateMachine.tryEvent(.startMembersFlow(entryPoint: .roomMember(userID: userID)))
            case .presentMessageForwarding(let forwardingItem):
                stateMachine.tryEvent(.presentMessageForwarding(forwardingItem: forwardingItem))
            case .presentResolveSendFailure(let failure, let sendHandle):
                stateMachine.tryEvent(.presentResolveSendFailure(failure: failure,
                                                                 sendHandle: sendHandle))
            }
        }
        .store(in: &cancellables)
                
        navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            guard let self else { return }
            stateMachine.tryEvent(.dismissThread)
            childThreadScreenCoordinators.removeAll { $0 === coordinator }
        }
        
        childThreadScreenCoordinators.append(coordinator)
    }
    
    private func presentJoinRoomScreen(via: [String], animated: Bool) {
        let coordinator = JoinRoomScreenCoordinator(parameters: .init(source: .generic(roomID: roomID, via: via),
                                                                      userSession: userSession,
                                                                      userIndicatorController: flowParameters.userIndicatorController,
                                                                      appSettings: flowParameters.appSettings))
        
        joinRoomScreenCoordinator = coordinator
        
        coordinator.actionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .joined(.roomID(let roomID)):
                    Task { [weak self] in
                        guard let self else { return }
                        
                        if case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) {
                            await storeAndSubscribeToRoomProxy(roomProxy)
                            stateMachine.tryEvent(.presentRoom(presentationAction: nil), userInfo: EventUserInfo(animated: animated))
                            
                            flowParameters.analytics.trackJoinedRoom(isDM: roomProxy.infoPublisher.value.isDirect,
                                                                     isSpace: roomProxy.infoPublisher.value.isSpace,
                                                                     activeMemberCount: UInt(roomProxy.infoPublisher.value.activeMembersCount))
                        } else {
                            stateMachine.tryEvent(.dismissFlow, userInfo: EventUserInfo(animated: animated))
                        }
                    }
                case .joined(.space(let spaceRoomListProxy)):
                    stateMachine.tryEvent(.joinedSpace, userInfo: EventUserInfo(animated: true, spaceRoomListProxy: spaceRoomListProxy))
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
    
    private func dismissFlow(animated: Bool, continuingWith spaceRoomListProxy: SpaceRoomListProxyProtocol? = nil) {
        childRoomFlowCoordinator?.clearRoute(animated: animated)
        
        if isChildFlow {
            // We don't support dismissing a child flow by itself, only the entire chain.
            MXLog.info("Leaving the rest of the navigation clean-up to the parent flow.")
            
            if joinRoomScreenCoordinator != nil {
                navigationStackCoordinator.pop()
            }
        } else {
            navigationStackCoordinator.popToRoot(animated: false)
            
            // Leave the root alone when it is about to be replaced by the space flow, otherwise when running on
            // iPhone the compact module diffs call the dismissal callback and we present a blank space flow 🙈
            if spaceRoomListProxy == nil {
                navigationStackCoordinator.setRootCoordinator(nil, animated: false)
            }
        }
        
        timelineController = nil
        
        if let spaceRoomListProxy {
            actionsSubject.send(.continueWithSpaceFlow(spaceRoomListProxy))
        } else {
            actionsSubject.send(.finished)
        }
        flowParameters.analytics.signpost.endRoomFlow()
    }
    
    private func presentRoomDetails(isRoot: Bool, animated: Bool) async {
        let params = RoomDetailsScreenCoordinatorParameters(roomProxy: roomProxy,
                                                            userSession: userSession,
                                                            analyticsService: flowParameters.analytics,
                                                            userIndicatorController: flowParameters.userIndicatorController,
                                                            notificationSettings: userSession.clientProxy.notificationSettings,
                                                            attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                            appSettings: flowParameters.appSettings)
        let coordinator = RoomDetailsScreenCoordinator(parameters: params)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .leftRoom:
                stateMachine.tryEvent(.dismissFlow)
            case .presentRoomMembersList:
                stateMachine.tryEvent(.startMembersFlow(entryPoint: .roomMembersList))
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
                stateMachine.tryEvent(.startMembersFlow(entryPoint: .roomMember(userID: userID)))
            case .presentReportRoomScreen:
                stateMachine.tryEvent(.presentReportRoomScreen)
            case .transferOwnership:
                presentTransferOwnershipScreen()
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
    
    private func presentKnockRequestsList() {
        let parameters = KnockRequestsListScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                      mediaProvider: userSession.mediaProvider,
                                                                      userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = KnockRequestsListScreenCoordinator(parameters: parameters)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissKnockRequestsListScreen)
        }
    }
    
    private func presentRoomDetailsEditScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        
        let roomDetailsEditParameters = RoomDetailsEditScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                                   userSession: userSession,
                                                                                   mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: flowParameters.appSettings),
                                                                                   navigationStackCoordinator: stackCoordinator,
                                                                                   userIndicatorController: flowParameters.userIndicatorController,
                                                                                   orientationManager: flowParameters.appMediator.windowManager,
                                                                                   appSettings: flowParameters.appSettings)
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
                                                                  userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = ReportContentScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                navigationStackCoordinator.setSheetCoordinator(nil)
                
                switch action {
                case .cancel:
                    break
                case .finish:
                    flowParameters.userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonReportSubmitted, iconName: "checkmark"))
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissReportContent)
        }
    }
    
    private func presentMediaUploadPickerWithMode(_ mode: MediaPickerScreenMode,
                                                  timelineController: TimelineControllerProtocol,
                                                  animated: Bool) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(mode: mode,
                                                                  userIndicatorController: flowParameters.userIndicatorController,
                                                                  orientationManager: flowParameters.appMediator.windowManager) { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .selectedMediaAtURLs(let urls):
                stateMachine.tryEvent(.presentMediaUploadPreview(mediaURLs: urls),
                                      userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
            }
        }

        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            if case .mediaUploadPicker = self?.stateMachine.state {
                self?.stateMachine.tryEvent(.dismissMediaUploadPicker)
            }
        }
    }

    private func presentMediaUploadPreviewScreen(for mediaURLs: [URL],
                                                 timelineController: TimelineControllerProtocol,
                                                 animated: Bool) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let title: String? = if mediaURLs.count == 1 {
            mediaURLs.first?.lastPathComponent
        } else {
            nil
        }

        let parameters = MediaUploadPreviewScreenCoordinatorParameters(mediaURLs: mediaURLs,
                                                                       title: title,
                                                                       isRoomEncrypted: roomProxy.infoPublisher.value.isEncrypted,
                                                                       shouldShowCaptionWarning: flowParameters.appSettings.shouldShowMediaCaptionWarning,
                                                                       mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: flowParameters.appSettings),
                                                                       timelineController: timelineController,
                                                                       clientProxy: userSession.clientProxy,
                                                                       userIndicatorController: flowParameters.userIndicatorController)

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
    
    private func presentEmojiPicker(for itemID: TimelineItemIdentifier,
                                    selectedEmoji: Set<String>,
                                    timelineController: TimelineControllerProtocol,
                                    animated: Bool) {
        let params = EmojiPickerScreenCoordinatorParameters(itemID: itemID,
                                                            selectedEmojis: selectedEmoji,
                                                            emojiProvider: flowParameters.emojiProvider,
                                                            timelineController: timelineController)
        let coordinator = EmojiPickerScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissEmojiPicker)
        }
    }

    private func presentMapNavigator(interactionMode: StaticLocationInteractionMode,
                                     timelineController: TimelineControllerProtocol,
                                     animated: Bool) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let params = StaticLocationScreenCoordinatorParameters(interactionMode: interactionMode,
                                                               mapURLBuilder: flowParameters.appSettings.mapTilerConfiguration,
                                                               timelineController: timelineController,
                                                               appMediator: flowParameters.appMediator,
                                                               analytics: flowParameters.analytics,
                                                               userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = StaticLocationScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
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
    
    private func presentPollForm(mode: PollFormMode, timelineController: TimelineControllerProtocol) {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = PollFormScreenCoordinator(parameters: .init(mode: mode,
                                                                      timelineController: timelineController,
                                                                      analytics: flowParameters.analytics,
                                                                      userIndicatorController: flowParameters.userIndicatorController))
        stackCoordinator.setRootCoordinator(coordinator)

        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .close:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissPollForm)
        }
    }
    
    private func presentRoomPollsHistory(animated: Bool) async {
        let userID = userSession.clientProxy.userID
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
                
        let timelineController = flowParameters.timelineControllerFactory.buildTimelineController(roomProxy: roomProxy,
                                                                                                  initialFocussedEventID: nil,
                                                                                                  timelineItemFactory: timelineItemFactory,
                                                                                                  mediaProvider: userSession.mediaProvider)
        
        let parameters = RoomPollsHistoryScreenCoordinatorParameters(pollInteractionHandler: PollInteractionHandler(analyticsService: flowParameters.analytics,
                                                                                                                    timelineController: timelineController),
                                                                     timelineController: timelineController,
                                                                     userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = RoomPollsHistoryScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .editPoll(let pollStartID, let poll):
                    stateMachine.tryEvent(.presentPollForm(mode: .edit(eventID: pollStartID, poll: poll)),
                                          userInfo: EventUserInfo(animated: animated, timelineController: timelineController))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissPollsHistory)
        }
    }
    
    private func presentMessageForwarding(with forwardingItem: MessageForwardingItem) {
        let roomSummaryProvider = userSession.clientProxy.alternateRoomSummaryProvider
        
        let stackCoordinator = NavigationStackCoordinator()
        
        let parameters = MessageForwardingScreenCoordinatorParameters(forwardingItem: forwardingItem,
                                                                      userSession: userSession,
                                                                      roomSummaryProvider: roomSummaryProvider,
                                                                      userIndicatorController: flowParameters.userIndicatorController)
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
                                                                         isModallyPresented: true,
                                                                         appSettings: flowParameters.appSettings)
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
        let stackCoordinator = NavigationStackCoordinator()
        let inviteParameters = InviteUsersScreenCoordinatorParameters(userSession: userSession,
                                                                      roomProxy: roomProxy,
                                                                      isCreatingRoom: false,
                                                                      userDiscoveryService: UserDiscoveryService(clientProxy: userSession.clientProxy),
                                                                      userIndicatorController: flowParameters.userIndicatorController,
                                                                      appSettings: flowParameters.appSettings)
        
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        stackCoordinator.setRootCoordinator(coordinator)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissInviteUsersScreen)
        }
    }
    
    private func presentRolesAndPermissionsScreen() {
        let parameters = RoomRolesAndPermissionsFlowCoordinatorParameters(roomProxy: roomProxy,
                                                                          mediaProvider: userSession.mediaProvider,
                                                                          navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: flowParameters.userIndicatorController,
                                                                          analytics: flowParameters.analytics)
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
                                                                                            userIndicatorController: flowParameters.userIndicatorController))
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
                                                                                userIndicatorController: flowParameters.userIndicatorController))
        
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
                                                                             userIndicatorController: flowParameters.userIndicatorController))
        
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
                                                                        userIndicatorController: flowParameters.userIndicatorController))
        
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
                                                                             userIndicatorController: flowParameters.userIndicatorController))
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
    
    private func startChildFlow(for roomID: String, via: [String], entryPoint: RoomFlowCoordinatorEntryPoint) {
        let coordinator = RoomFlowCoordinator(roomID: roomID,
                                              isChildFlow: true,
                                              navigationStackCoordinator: navigationStackCoordinator,
                                              flowParameters: flowParameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            case .continueWithSpaceFlow(let spaceRoomListProxy):
                stateMachine.tryEvent(.startSpaceFlow, userInfo: EventUserInfo(animated: true, spaceRoomListProxy: spaceRoomListProxy))
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
        case .transferOwnership:
            coordinator.handleAppRoute(.transferOwnership(roomID: roomID), animated: true)
        case .thread:
            fatalError("This entry point is not allowed for child flows")
        }
    }
    
    private func startPinnedEventsTimelineFlow() {
        let stackCoordinator = NavigationStackCoordinator()
        
        let flowCoordinator = PinnedEventsTimelineFlowCoordinator(roomProxy: roomProxy,
                                                                  navigationStackCoordinator: stackCoordinator,
                                                                  flowParameters: flowParameters)
        
        flowCoordinator.actionsPublisher.sink { [weak self] action in
            guard let self else {
                return
            }
            
            switch action {
            case .finished:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .displayUser(let userID):
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.startMembersFlow(entryPoint: .roomMember(userID: userID)))
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
        let flowCoordinator = MediaEventsTimelineFlowCoordinator(roomProxy: roomProxy,
                                                                 navigationStackCoordinator: navigationStackCoordinator,
                                                                 flowParameters: flowParameters)
        
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
            case .displayMessageForwarding(let forwardingItem):
                stateMachine.tryEvent(.presentMessageForwarding(forwardingItem: forwardingItem))
            }
        }
        .store(in: &cancellables)
        
        mediaEventsTimelineFlowCoordinator = flowCoordinator
        
        flowCoordinator.start()
    }
    
    private func startSpaceFlow(spaceRoomListProxy: SpaceRoomListProxyProtocol, animated: Bool) {
        let coordinator = SpaceFlowCoordinator(entryPoint: .space(spaceRoomListProxy),
                                               spaceServiceProxy: userSession.clientProxy.spaceService,
                                               isChildFlow: true,
                                               navigationStackCoordinator: navigationStackCoordinator,
                                               flowParameters: flowParameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .presentCallScreen(let roomProxy):
                    actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
                case .verifyUser(let userID):
                    actionsSubject.send(.verifyUser(userID: userID))
                case .finished:
                    stateMachine.tryEvent(.finishedSpaceFlow)
                }
            }
            .store(in: &cancellables)
        
        spaceFlowCoordinator = coordinator
        
        coordinator.start(animated: animated)
    }
    
    private func startMembersFlow(entryPoint: RoomMembersFlowCoordinatorEntryPoint, animated: Bool) {
        let flowCoordinator = RoomMembersFlowCoordinator(entryPoint: entryPoint,
                                                         roomProxy: roomProxy,
                                                         navigationStackCoordinator: navigationStackCoordinator,
                                                         flowParameters: flowParameters)
        
        flowCoordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .finished:
                stateMachine.tryEvent(.stopMembersFlow)
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)
        
        flowCoordinator.start(animated: animated)
        membersFlowCoordinator = flowCoordinator
    }
    
    private static let loadingIndicatorID = "\(RoomFlowCoordinator.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil,
                                      title: String = L10n.commonLoading,
                                      message: String? = nil) {
        flowParameters.userIndicatorController.submitIndicator(.init(id: Self.loadingIndicatorID,
                                                                     type: .modal(progress: .indeterminate,
                                                                                  interactiveDismissDisabled: false,
                                                                                  allowsInteraction: false),
                                                                     title: title,
                                                                     message: message,
                                                                     persistent: true),
                                                               delay: delay)
    }
    
    private func hideLoadingIndicator() {
        flowParameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
    
    private func showErrorIndicator() {
        flowParameters.userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
    }
}
