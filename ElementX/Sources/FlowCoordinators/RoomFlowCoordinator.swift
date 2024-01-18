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

import Combine
import Foundation
import SwiftState
import UserNotifications

enum RoomFlowCoordinatorAction: Equatable {
    case presentedRoom(String)
    case dismissedRoom
    case presentCallScreen(roomProxy: RoomProxyProtocol)
    
    static func == (lhs: RoomFlowCoordinatorAction, rhs: RoomFlowCoordinatorAction) -> Bool {
        switch (lhs, rhs) {
        case (.presentedRoom(let lhsRoomID), .presentedRoom(let rhsRoomID)):
            return lhsRoomID == rhsRoomID
        case (.dismissedRoom, .dismissedRoom):
            return true
        case (.presentCallScreen(let lhsRoomProxy), .presentCallScreen(let rhsRoomProxy)):
            return lhsRoomProxy.id == rhsRoomProxy.id
        default:
            return false
        }
    }
}

// swiftlint:disable file_length
class RoomFlowCoordinator: FlowCoordinatorProtocol {
    private let windowManager: WindowManagerProtocol
    private let userSession: UserSessionProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let emojiProvider: EmojiProviderProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let stateMachine: StateMachine<State, Event> = .init(state: .initial)
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var roomProxy: RoomProxyProtocol? {
        didSet {
            oldValue?.unsubscribeFromUpdates()
        }
    }
    
    private var timelineController: RoomTimelineControllerProtocol?
    
    init(userSession: UserSessionProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         emojiProvider: EmojiProviderProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         windowManager: WindowManagerProtocol) {
        self.userSession = userSession
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.navigationStackCoordinator = navigationStackCoordinator
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.emojiProvider = emojiProvider
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.windowManager = windowManager
        
        setupStateMachine()
    }
        
    // MARK: - FlowCoordinatorProtocol
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .room(let roomID):
            if case .room(let identifier) = stateMachine.state,
               roomID == identifier {
                return
            }
            
            stateMachine.tryEvent(.presentRoom(roomID: roomID), userInfo: EventUserInfo(animated: animated))
        case .roomDetails(let roomID):
            stateMachine.tryEvent(.presentRoomDetails(roomID: roomID), userInfo: EventUserInfo(animated: animated))
        case .roomList:
            stateMachine.tryEvent(.dismissRoom, userInfo: EventUserInfo(animated: animated))
        case .roomMemberDetails(let userID):
            Task {
                switch await roomProxy?.getMember(userID: userID) {
                case .success(let member):
                    stateMachine.tryEvent(.presentRoomMemberDetails(member: .init(value: member)))
                case .failure(let error):
                    MXLog.error("[RoomFlowCoordinator] Failed to get member: \(error)")
                case .none:
                    MXLog.error("[RoomFlowCoordinator] Failed to get member: RoomProxy is nil")
                }
            }
        case .genericCallLink, .oidcCallback, .settings, .chatBackupSettings:
            break
        }
    }

    func clearRoute(animated: Bool) {
        guard stateMachine.state != .initial else {
            return
        }
        stateMachine.tryEvent(.dismissRoom, userInfo: EventUserInfo(animated: animated))
    }
    
    // MARK: - Private
    
    // swiftlint:disable:next function_body_length
    private func setupStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (_, .presentRoom(let roomID)):
                return .room(roomID: roomID)
            case (.room, .dismissRoom):
                return .initial
                
            case (.initial, .presentRoomDetails(let roomID)):
                return .roomDetails(roomID: roomID, isRoot: true)
            case (.room(let currentRoomID), .presentRoomDetails(let roomID)):
                return .roomDetails(roomID: roomID, isRoot: roomID != currentRoomID)
            case (.roomDetails(let currentRoomID, _), .presentRoomDetails(let roomID)):
                return .roomDetails(roomID: roomID, isRoot: roomID != currentRoomID)
            case (.roomDetails(let roomID, _), .dismissRoomDetails):
                return .room(roomID: roomID)
            case (.roomDetails, .dismissRoom):
                return .initial
                
            case (.roomDetails(let roomID, _), .presentRoomDetailsEditScreen):
                return .roomDetailsEditScreen(roomID: roomID)
            case (.roomDetailsEditScreen(let roomID), .dismissRoomDetailsEditScreen):
                return .roomDetails(roomID: roomID, isRoot: false)
                
            case (.roomDetails(let roomID, _), .presentNotificationSettingsScreen):
                return .notificationSettings(roomID: roomID)
            case (.notificationSettings(let roomID), .dismissNotificationSettingsScreen):
                return .roomDetails(roomID: roomID, isRoot: false)
                
            case (.notificationSettings(let roomID), .presentGlobalNotificationSettingsScreen):
                return .globalNotificationSettings(roomID: roomID)
            case (.globalNotificationSettings(let roomID), .dismissGlobalNotificationSettingsScreen):
                return .notificationSettings(roomID: roomID)
                
            case (.roomDetails(let roomID, _), .presentRoomMembersList):
                return .roomMembersList(roomID: roomID)
            case (.roomMembersList(let roomID), .dismissRoomMembersList):
                return .roomDetails(roomID: roomID, isRoot: false)

            case (.room(let roomID), .presentRoomMemberDetails(let member)):
                return .roomMemberDetails(roomID: roomID, member: member, fromRoomMembersList: false)
            case (.roomMembersList(let roomID), .presentRoomMemberDetails(let member)):
                return .roomMemberDetails(roomID: roomID, member: member, fromRoomMembersList: true)
            case (.roomMemberDetails(let roomID, _, let fromRoomMembersList), .dismissRoomMemberDetails):
                return fromRoomMembersList ? .roomMembersList(roomID: roomID) : .room(roomID: roomID)
                
            case (.roomDetails(let roomID, _), .presentInviteUsersScreen):
                return .inviteUsersScreen(roomID: roomID, fromRoomMembersList: false)
            case (.roomMembersList(let roomID), .presentInviteUsersScreen):
                return .inviteUsersScreen(roomID: roomID, fromRoomMembersList: true)
            case (.inviteUsersScreen(let roomID, let fromRoomMembersList), .dismissInviteUsersScreen):
                return fromRoomMembersList ? .roomMembersList(roomID: roomID) : .roomDetails(roomID: roomID, isRoot: false)
                
            case (.room(let roomID), .presentReportContent(let itemID, let senderID)):
                return .reportContent(roomID: roomID, itemID: itemID, senderID: senderID)
            case (.reportContent(let roomID, _, _), .dismissReportContent):
                return .room(roomID: roomID)
                
            case (.room(let roomID), .presentMediaUploadPicker(let source)):
                return .mediaUploadPicker(roomID: roomID, source: source)
            case (.mediaUploadPicker(let roomID, _), .dismissMediaUploadPicker):
                return .room(roomID: roomID)
                
            case (.mediaUploadPicker(let roomID, _), .presentMediaUploadPreview(let fileURL)):
                return .mediaUploadPreview(roomID: roomID, fileURL: fileURL)
            case (.room(let roomID), .presentMediaUploadPreview(let fileURL)):
                return .mediaUploadPreview(roomID: roomID, fileURL: fileURL)
            case (.mediaUploadPreview(let roomID, _), .dismissMediaUploadPreview):
                return .room(roomID: roomID)
                
            case (.room(let roomID), .presentEmojiPicker(let itemID, let selectedEmoji)):
                return .emojiPicker(roomID: roomID, itemID: itemID, selectedEmojis: selectedEmoji)
            case (.emojiPicker(let roomID, _, _), .dismissEmojiPicker):
                return .room(roomID: roomID)

            case (.room(let roomID), .presentMessageForwarding(let itemID)):
                return .messageForwarding(roomID: roomID, itemID: itemID)
            case (.messageForwarding(let roomID, _), .dismissMessageForwarding):
                return .room(roomID: roomID)

            case (.room(let roomID), .presentMapNavigator):
                return .mapNavigator(roomID: roomID)
            case (.mapNavigator(let roomID), .dismissMapNavigator):
                return .room(roomID: roomID)
            
            case (.room(let roomID), .presentPollForm):
                return .pollForm(roomID: roomID)
            case (.pollForm(let roomID), .dismissPollForm):
                return .room(roomID: roomID)
            
            case (.roomDetails(let roomID, _), .presentPollsHistory):
                return .pollsHistory(roomID: roomID)
            case (.pollsHistory(let roomID), .dismissPollsHistory):
                return .roomDetails(roomID: roomID, isRoot: false)
            
            case (.pollsHistory(let roomID), .presentPollForm):
                return .pollsHistoryForm(roomID: roomID)
            case (.pollsHistoryForm(let roomID), .dismissPollForm):
                return .pollsHistory(roomID: roomID)
            
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            
            let animated = (context.userInfo as? EventUserInfo)?.animated ?? true
            
            switch (context.fromState, context.event, context.toState) {
            case (.roomDetails(roomID: let currentRoomID, true), .presentRoom(let roomID), .room) where currentRoomID == roomID:
                dismissRoom(animated: animated)
                presentRoom(roomID, animated: animated)
            case (_, .presentRoom(let roomID), .room):
                let destinationRoomProxy = (context.userInfo as? EventUserInfo)?.destinationRoomProxy
                presentRoom(roomID, animated: animated, destinationRoomProxy: destinationRoomProxy)
            case (.room, .dismissRoom, .initial):
                dismissRoom(animated: animated)
            
            case (.roomDetails(let currentRoomID, _), .presentRoomDetails, .roomDetails(let roomID, _)) where currentRoomID == roomID:
                break
            case (.initial, .presentRoomDetails, .roomDetails(let roomID, let isRoot)),
                 (.room, .presentRoomDetails, .roomDetails(let roomID, let isRoot)),
                 (.roomDetails, .presentRoomDetails, .roomDetails(let roomID, let isRoot)):
                self.presentRoomDetails(roomID: roomID, isRoot: isRoot, animated: animated)
            case (.roomDetails, .dismissRoomDetails, .room):
                break
            case (.roomDetails, .dismissRoom, .initial):
                dismissRoom(animated: animated)
                
            case (.roomDetails, .presentRoomDetailsEditScreen(let accountOwner), .roomDetailsEditScreen):
                presentRoomDetailsEditScreen(accountOwner: accountOwner.value)
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
                
            case (.room, .presentRoomMemberDetails, .roomMemberDetails(_, let member, _)):
                presentRoomMemberDetails(member: member.value)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .room):
                break
                
            case (.roomMembersList, .presentRoomMemberDetails, .roomMemberDetails(_, let member, _)):
                presentRoomMemberDetails(member: member.value)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .roomMembersList):
                break
                
            case (.roomDetails, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
            case (.inviteUsersScreen, .dismissInviteUsersScreen, .roomDetails):
                break
                
            case (.roomMembersList, .presentInviteUsersScreen, .inviteUsersScreen):
                presentInviteUsersScreen()
            case (.inviteUsersScreen, .dismissInviteUsersScreen, .roomMembersList):
                break
                
            case (.room, .presentReportContent, .reportContent(_, let itemID, let senderID)):
                presentReportContent(for: itemID, from: senderID)
            case (.reportContent, .dismissReportContent, .room):
                break
                
            case (.room, .presentMediaUploadPicker, .mediaUploadPicker(_, let source)):
                presentMediaUploadPickerWithSource(source)
            case (.mediaUploadPicker, .dismissMediaUploadPicker, .room):
                break
                
            case (.mediaUploadPicker, .presentMediaUploadPreview, .mediaUploadPreview(_, let fileURL)):
                presentMediaUploadPreviewScreen(for: fileURL)
            case (.room, .presentMediaUploadPreview, .mediaUploadPreview(_, let fileURL)):
                presentMediaUploadPreviewScreen(for: fileURL)
            case (.mediaUploadPreview, .dismissMediaUploadPreview, .room):
                break
                
            case (.room, .presentEmojiPicker, .emojiPicker(_, let itemID, let selectedEmoji)):
                presentEmojiPicker(for: itemID, selectedEmoji: selectedEmoji)
            case (.emojiPicker, .dismissEmojiPicker, .room):
                break
                
            case (.room, .presentMessageForwarding(let itemID), .messageForwarding):
                presentMessageForwarding(for: itemID)
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

            case (.roomDetails(let roomID, _), .presentPollsHistory, .pollsHistory):
                presentPollsHistory(roomID: roomID)
            case (.pollsHistory, .dismissPollsHistory, .roomDetails):
                break
        
            case (.pollsHistory, .presentPollForm(let mode), .pollsHistoryForm):
                presentPollForm(mode: mode)
            case (.pollsHistoryForm, .dismissPollForm, .pollsHistory):
                break
            
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
    ///   - roomID: the identifier of the room that is to be presented
    ///   - animated: whether it should animate the transition
    ///   - destinationRoomProxy: an optional already build roomProxy for the target room. It is currently used when
    ///   forwarding messages so that we can take advantage of the local echo
    ///   and have the message already there when presenting the room
    private func presentRoom(_ roomID: String, animated: Bool, destinationRoomProxy: RoomProxyProtocol? = nil) {
        Task {
            await asyncPresentRoom(roomID, animated: animated, destinationRoomProxy: destinationRoomProxy)
        }
    }
    
    private func asyncPresentRoom(_ roomID: String, animated: Bool, destinationRoomProxy: RoomProxyProtocol? = nil) async {
        // If any sheets are presented dismiss them, rely on their dismissal callbacks to transition the state machine
        // through the correct states before presenting the room
        navigationStackCoordinator.setSheetCoordinator(nil)
        
        if let roomProxy, roomProxy.id == roomID {
            navigationStackCoordinator.popToRoot()
            return
        }
        
        let roomProxy: RoomProxyProtocol
        
        if let destinationRoomProxy {
            roomProxy = destinationRoomProxy
        } else {
            guard let proxy = await userSession.clientProxy.roomForIdentifier(roomID) else {
                MXLog.error("Invalid room identifier: \(roomID)")
                stateMachine.tryEvent(.dismissRoom)
                return
            }
            
            roomProxy = proxy
        }
        
        await roomProxy.subscribeForUpdates()
        
        actionsSubject.send(.presentedRoom(roomID))
        
        self.roomProxy = roomProxy
        
        let userID = userSession.clientProxy.userID
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: appSettings.permalinkBaseURL,
                                                                                                           mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
                
        let timelineController = roomTimelineControllerFactory.buildRoomTimelineController(roomProxy: roomProxy,
                                                                                           timelineItemFactory: timelineItemFactory,
                                                                                           secureBackupController: userSession.clientProxy.secureBackupController)
        self.timelineController = timelineController
        
        analytics.trackViewRoom(isDM: roomProxy.isDirect, isSpace: roomProxy.isSpace)
        
        let completionSuggestionService = CompletionSuggestionService(roomProxy: roomProxy)
        
        let parameters = RoomScreenCoordinatorParameters(roomProxy: roomProxy,
                                                         timelineController: timelineController,
                                                         mediaProvider: userSession.mediaProvider,
                                                         mediaPlayerProvider: MediaPlayerProvider(),
                                                         voiceMessageMediaManager: userSession.voiceMessageMediaManager,
                                                         emojiProvider: emojiProvider,
                                                         completionSuggestionService: completionSuggestionService,
                                                         appSettings: appSettings)
        let coordinator = RoomScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoomDetails:
                    stateMachine.tryEvent(.presentRoomDetails(roomID: roomID))
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
                case .presentRoomMemberDetails(member: let member):
                    stateMachine.tryEvent(.presentRoomMemberDetails(member: .init(value: member)))
                case .presentMessageForwarding(let itemID):
                    stateMachine.tryEvent(.presentMessageForwarding(itemID: itemID))
                case .presentCallScreen:
                    guard let roomProxy = self.roomProxy else {
                        fatalError()
                    }
                    
                    actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator, animated: animated) { [weak self] in
            // Move the state machine to no room selected if the room currently being dismissed
            // is the same as the one selected in the state machine.
            // This generally happens when popping the room screen while in a compact layout
            switch self?.stateMachine.state {
            case let .room(selectedRoomID) where selectedRoomID == roomID:
                self?.stateMachine.tryEvent(.dismissRoom)
            default:
                break
            }
        }
        
        if navigationSplitCoordinator.detailCoordinator == nil {
            navigationSplitCoordinator.setDetailCoordinator(navigationStackCoordinator, animated: animated)
        }
    }
    
    private func dismissRoom(animated: Bool) {
        // DON'T CHANGE THE ORDER IN WHICH POP AND SET ARE DONE, IT CAN CAUSE A CRASH
        navigationStackCoordinator.popToRoot(animated: false)
        navigationSplitCoordinator.setDetailCoordinator(nil, animated: animated)
        roomProxy = nil
        timelineController = nil
        
        actionsSubject.send(.dismissedRoom)
    }
    
    private func presentRoomDetails(roomID: String, isRoot: Bool, animated: Bool) {
        Task {
            await asyncPresentRoomDetails(roomID: roomID, isRoot: isRoot, animated: animated)
        }
    }
    
    private func asyncPresentRoomDetails(roomID: String, isRoot: Bool, animated: Bool) async {
        if isRoot {
            roomProxy = await userSession.clientProxy.roomForIdentifier(roomID)
            await roomProxy?.subscribeForUpdates()
        } else {
            await asyncPresentRoom(roomID, animated: animated)
        }
        
        guard let roomProxy else {
            MXLog.error("Invalid room identifier: \(roomID)")
            stateMachine.tryEvent(.dismissRoom)
            return
        }
        
        let params = RoomDetailsScreenCoordinatorParameters(accountUserID: userSession.userID,
                                                            roomProxy: roomProxy,
                                                            mediaProvider: userSession.mediaProvider,
                                                            userIndicatorController: userIndicatorController,
                                                            notificationSettings: userSession.clientProxy.notificationSettings,
                                                            attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: appSettings.permalinkBaseURL,
                                                                                                             mentionBuilder: MentionBuilder()))
        let coordinator = RoomDetailsScreenCoordinator(parameters: params)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .leftRoom:
                dismissRoom(animated: animated)
            case .presentRoomMembersList:
                stateMachine.tryEvent(.presentRoomMembersList)
            case .presentRoomDetailsEditScreen(let accountOwner):
                stateMachine.tryEvent(.presentRoomDetailsEditScreen(accountOwner: .init(value: accountOwner)))
            case .presentNotificationSettingsScreen:
                stateMachine.tryEvent(.presentNotificationSettingsScreen)
            case .presentInviteUsersScreen:
                stateMachine.tryEvent(.presentInviteUsersScreen)
            case .presentPollsHistory:
                stateMachine.tryEvent(.presentPollsHistory)
            }
        }
        .store(in: &cancellables)
        
        if isRoot {
            navigationStackCoordinator.setRootCoordinator(coordinator, animated: animated) { [weak self] in
                guard let self else { return }
                if case .roomDetails(let detailsRoomID, _) = stateMachine.state, detailsRoomID == roomID {
                    stateMachine.tryEvent(.dismissRoom)
                }
            }
            
            if navigationSplitCoordinator.detailCoordinator == nil {
                navigationSplitCoordinator.setDetailCoordinator(navigationStackCoordinator, animated: animated)
            }
            
            actionsSubject.send(.presentedRoom(roomID))
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
        guard let roomProxy else {
            fatalError()
        }
        
        let params = RoomMembersListScreenCoordinatorParameters(mediaProvider: userSession.mediaProvider,
                                                                roomProxy: roomProxy)
        let coordinator = RoomMembersListScreenCoordinator(parameters: params)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .invite:
                    stateMachine.tryEvent(.presentInviteUsersScreen)
                case .selectedMember(let member):
                    stateMachine.tryEvent(.presentRoomMemberDetails(member: .init(value: member)))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomMembersList)
        }
    }
    
    private func presentRoomDetailsEditScreen(accountOwner: RoomMemberProxyProtocol) {
        guard let roomProxy else {
            fatalError()
        }
        
        let stackCoordinator = NavigationStackCoordinator()
        
        let roomDetailsEditParameters = RoomDetailsEditScreenCoordinatorParameters(accountOwner: accountOwner,
                                                                                   mediaProvider: userSession.mediaProvider,
                                                                                   navigationStackCoordinator: stackCoordinator,
                                                                                   roomProxy: roomProxy,
                                                                                   userIndicatorController: userIndicatorController,
                                                                                   windowManager: windowManager)
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
        guard let roomProxy, let eventID = itemID.eventID else {
            fatalError()
        }
        
        let stackCoordinator = NavigationStackCoordinator()
        let parameters = ReportContentScreenCoordinatorParameters(eventID: eventID,
                                                                  senderID: senderID,
                                                                  roomProxy: roomProxy,
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

        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: userIndicatorController, source: source, windowManager: windowManager) { [weak self] action in
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

    private func presentMediaUploadPreviewScreen(for url: URL) {
        guard let roomProxy else {
            fatalError()
        }
        
        let stackCoordinator = NavigationStackCoordinator()

        let parameters = MediaUploadPreviewScreenCoordinatorParameters(userIndicatorController: userIndicatorController,
                                                                       roomProxy: roomProxy,
                                                                       mediaUploadingPreprocessor: MediaUploadingPreprocessor(),
                                                                       title: url.lastPathComponent,
                                                                       url: url)

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
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
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
                    await self.timelineController?.toggleReaction(emoji, to: itemID)
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
        
        let params = StaticLocationScreenCoordinatorParameters(interactionMode: interactionMode)
        let coordinator = StaticLocationScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .selectedLocation(let geoURI, let isUserLocation):
                Task {
                    _ = await self.roomProxy?.timeline.sendLocation(body: geoURI.bodyMessage,
                                                                    geoURI: geoURI,
                                                                    description: nil,
                                                                    zoomLevel: 15,
                                                                    assetType: isUserLocation ? .sender : .pin)
                    self.navigationSplitCoordinator.setSheetCoordinator(nil)
                }
                
                self.analytics.trackComposer(inThread: false,
                                             isEditing: false,
                                             isReply: false,
                                             messageType: isUserLocation ? .location(.user) : .location(.pin),
                                             startsThread: nil)
            case .close:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
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

                self.navigationSplitCoordinator.setSheetCoordinator(nil)

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

        navigationSplitCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissPollForm)
        }
    }
    
    private func createPoll(question: String, options: [String], pollKind: Poll.Kind) {
        Task {
            guard let roomProxy = self.roomProxy else {
                self.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
                return
            }

            let result = await roomProxy.timeline.createPoll(question: question, answers: options, pollKind: pollKind)

            self.analytics.trackComposer(inThread: false,
                                         isEditing: false,
                                         isReply: false,
                                         messageType: .poll,
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
            guard let roomProxy = self.roomProxy else {
                self.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
                return
            }

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
            guard case .edit(let pollStartID, _) = mode, let roomProxy = self.roomProxy else {
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
    
    private func presentPollsHistory(roomID: String) {
        Task {
            await asyncPresentRoomPollsHistory(roomID: roomID)
        }
    }
    
    private func asyncPresentRoomPollsHistory(roomID: String) async {
        guard let roomProxy else {
            fatalError()
        }
                
        let userID = userSession.clientProxy.userID
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: appSettings.permalinkBaseURL,
                                                                                                           mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
                
        let roomTimelineController = roomTimelineControllerFactory.buildRoomTimelineController(roomProxy: roomProxy,
                                                                                               timelineItemFactory: timelineItemFactory,
                                                                                               secureBackupController: userSession.clientProxy.secureBackupController)
        
        let parameters = RoomPollsHistoryScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                     pollInteractionHandler: PollInteractionHandler(analyticsService: analytics, roomProxy: roomProxy),
                                                                     roomTimelineController: roomTimelineController)
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
    
    private func presentRoomMemberDetails(member: RoomMemberProxyProtocol) {
        guard let roomProxy else {
            fatalError()
        }
        
        let params = RoomMemberDetailsScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                  roomMemberProxy: member,
                                                                  mediaProvider: userSession.mediaProvider,
                                                                  userIndicatorController: userIndicatorController)
        let coordinator = RoomMemberDetailsScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .openDirectChat:
                let loadingIndicatorIdentifier = "OpenDirectChatLoadingIndicator"
                
                userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier,
                                                                      type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                      title: L10n.commonLoading,
                                                                      persistent: true))
                
                Task { [weak self] in
                    guard let self else { return }
                    
                    let currentDirectRoom = await userSession.clientProxy.directRoomForUserID(member.userID)
                    switch currentDirectRoom {
                    case .success(.some(let roomID)):
                        stateMachine.tryEvent(.presentRoom(roomID: roomID))
                    case .success(nil):
                        switch await userSession.clientProxy.createDirectRoom(with: member.userID, expectedRoomName: member.displayName) {
                        case .success(let roomID):
                            analytics.trackCreatedRoom(isDM: true)
                            stateMachine.tryEvent(.presentRoom(roomID: roomID))
                        case .failure:
                            userIndicatorController.alertInfo = .init(id: UUID())
                        }
                    case .failure:
                        userIndicatorController.alertInfo = .init(id: UUID())
                    }
                    
                    userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
                }
            }
        }
        .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomMemberDetails)
        }
    }
    
    private func presentMessageForwarding(for itemID: TimelineItemIdentifier) {
        guard let roomProxy, let roomSummaryProvider = userSession.clientProxy.messageForwardingRoomSummaryProvider, let eventID = itemID.eventID else {
            fatalError()
        }
        
        let stackCoordinator = NavigationStackCoordinator()
        
        let parameters = MessageForwardingScreenCoordinatorParameters(roomSummaryProvider: roomSummaryProvider,
                                                                      mediaProvider: userSession.mediaProvider,
                                                                      sourceRoomID: roomProxy.id)
        let coordinator = MessageForwardingScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            case .send(let roomID):
                navigationStackCoordinator.setSheetCoordinator(nil)
                
                Task {
                    await self.forward(eventID: eventID, toRoomID: roomID)
                }
            }
        }.store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMessageForwarding)
        }
    }
    
    private func forward(eventID: String, toRoomID roomID: String) async {
        guard let roomProxy else {
            MXLog.error("Failed retrieving current room with id: \(roomID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        guard let messageEventContent = roomProxy.timeline.messageEventContent(for: eventID) else {
            MXLog.error("Failed retrieving forwarded message event content for eventID: \(eventID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        guard let targetRoomProxy = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Failed retrieving room to forward to with id: \(roomID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        if case .failure(let error) = await targetRoomProxy.timeline.sendMessageEventContent(messageEventContent) {
            MXLog.error("Failed forwarding message with error: \(error)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        stateMachine.tryEvent(.presentRoom(roomID: roomID), userInfo: EventUserInfo(animated: true, destinationRoomProxy: targetRoomProxy))
    }
    
    private func presentNotificationSettingsScreen() {
        guard let roomProxy else {
            fatalError()
        }
        
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
        guard let roomProxy else {
            fatalError()
        }
        
        let selectedUsersSubject: CurrentValueSubject<[UserProfileProxy], Never> = .init([])
        
        let stackCoordinator = NavigationStackCoordinator()
        let inviteParameters = InviteUsersScreenCoordinatorParameters(selectedUsers: .init(selectedUsersSubject),
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
    
    private func inviteUsers(_ users: [String], in room: RoomProxyProtocol) {
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

    enum State: StateType {
        case initial
        case room(roomID: String)
        case roomDetails(roomID: String, isRoot: Bool)
        case roomDetailsEditScreen(roomID: String)
        case notificationSettings(roomID: String)
        case globalNotificationSettings(roomID: String)
        case roomMembersList(roomID: String)
        case roomMemberDetails(roomID: String, member: HashableRoomMemberWrapper, fromRoomMembersList: Bool)
        case inviteUsersScreen(roomID: String, fromRoomMembersList: Bool)
        case mediaUploadPicker(roomID: String, source: MediaPickerScreenSource)
        case mediaUploadPreview(roomID: String, fileURL: URL)
        case emojiPicker(roomID: String, itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
        case mapNavigator(roomID: String)
        case messageForwarding(roomID: String, itemID: TimelineItemIdentifier)
        case reportContent(roomID: String, itemID: TimelineItemIdentifier, senderID: String)
        case pollForm(roomID: String)
        case pollsHistory(roomID: String)
        case pollsHistoryForm(roomID: String)
    }
    
    struct EventUserInfo {
        let animated: Bool
        var destinationRoomProxy: RoomProxyProtocol?
    }

    enum Event: EventType {
        case presentRoom(roomID: String)
        case dismissRoom
        
        case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
        case dismissReportContent
        
        case presentRoomDetails(roomID: String)
        case dismissRoomDetails
        
        case presentRoomDetailsEditScreen(accountOwner: HashableRoomMemberWrapper)
        case dismissRoomDetailsEditScreen
        
        case presentNotificationSettingsScreen
        case dismissNotificationSettingsScreen
        
        case presentGlobalNotificationSettingsScreen
        case dismissGlobalNotificationSettingsScreen
        
        case presentRoomMembersList
        case dismissRoomMembersList
        
        case presentRoomMemberDetails(member: HashableRoomMemberWrapper)
        case dismissRoomMemberDetails
        
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
        
        case presentMessageForwarding(itemID: TimelineItemIdentifier)
        case dismissMessageForwarding

        case presentPollForm(mode: PollFormMode)
        case dismissPollForm
        
        case presentPollsHistory
        case dismissPollsHistory
    }
}

private extension GeoURI {
    var bodyMessage: String {
        "Location was shared at \(string)"
    }
}

private extension Result {
    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}
