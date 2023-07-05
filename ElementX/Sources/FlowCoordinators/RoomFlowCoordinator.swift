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

enum RoomFlowCoordinatorAction: Equatable {
    case presentedRoom(String)
    case dismissedRoom
}

class RoomFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let navigationSplitCoordinator: NavigationSplitCoordinator
    private let emojiProvider: EmojiProviderProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let stateMachine: StateMachine<State, Event> = .init(state: .initial)
    
    private var cancellables: Set<AnyCancellable> = .init()
    
    private let actionsSubject: PassthroughSubject<RoomFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var roomProxy: RoomProxyProtocol?
    private var timelineController: RoomTimelineControllerProtocol?
    
    init(userSession: UserSessionProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         navigationSplitCoordinator: NavigationSplitCoordinator,
         emojiProvider: EmojiProviderProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.navigationStackCoordinator = navigationStackCoordinator
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.emojiProvider = emojiProvider
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
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
        case .invites:
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
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func setupStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (event, fromState) {
            case (.presentRoom(let roomID), _):
                return .room(roomID: roomID)
            case (.dismissRoom, .room):
                return .initial
                
            case (.presentRoomDetails(let roomID), .initial):
                return .roomDetails(roomID: roomID, isRoot: true)
            case (.presentRoomDetails(let roomID), .room(let currentRoomID)):
                return .roomDetails(roomID: roomID, isRoot: roomID != currentRoomID)
            case (.presentRoomDetails(let roomID), .roomDetails(let currentRoomID, _)):
                return .roomDetails(roomID: roomID, isRoot: roomID != currentRoomID)
            case (.dismissRoomDetails, .roomDetails(let roomID, _)):
                return .room(roomID: roomID)
            case (.dismissRoom, .roomDetails):
                return .initial

            case (.presentRoomMemberDetails(let member), .room(let roomID)):
                return .roomMemberDetails(roomID: roomID, member: member)
            case (.dismissRoomMemberDetails, .roomMemberDetails(let roomID, _)):
                return .room(roomID: roomID)
                
            case (.presentReportContent(let itemID, let senderID), .room(let roomID)):
                return .reportContent(roomID: roomID, itemID: itemID, senderID: senderID)
            case (.dismissReportContent, .reportContent(let roomID, _, _)):
                return .room(roomID: roomID)
                
            case (.presentMediaUploadPicker(let source), .room(let roomID)):
                return .mediaUploadPicker(roomID: roomID, source: source)
            case (.dismissMediaUploadPicker, .mediaUploadPicker(let roomID, _)):
                return .room(roomID: roomID)
                
            case (.presentMediaUploadPreview(let fileURL), .mediaUploadPicker(let roomID, _)):
                return .mediaUploadPreview(roomID: roomID, fileURL: fileURL)
            case (.presentMediaUploadPreview(let fileURL), .room(let roomID)):
                return .mediaUploadPreview(roomID: roomID, fileURL: fileURL)
            case (.dismissMediaUploadPreview, .mediaUploadPreview(let roomID, _)):
                return .room(roomID: roomID)
                
            case (.presentEmojiPicker(let itemID), .room(let roomID)):
                return .emojiPicker(roomID: roomID, itemID: itemID)
            case (.dismissEmojiPicker, .emojiPicker(let roomID, _)):
                return .room(roomID: roomID)

            case (.presentMessageForwarding(let itemID), .room(let roomID)):
                return .messageForwarding(roomID: roomID, itemID: itemID)
            case (.dismissMessageForwarding, .messageForwarding(let roomID, _)):
                return .room(roomID: roomID)
            case (.presentMapNavigator, .room(let roomID)):
                return .mapNavigator(roomID: roomID)
            case (.dismissMapNavigator, .mapNavigator(let roomID)):
                return .room(roomID: roomID)
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
                
            case (.room, .presentEmojiPicker, .emojiPicker(_, let itemID)):
                presentEmojiPicker(for: itemID)
            case (.emojiPicker, .dismissEmojiPicker, .room):
                break

            case (.room, .presentRoomMemberDetails, .roomMemberDetails(_, let member)):
                presentRoomMemberDetails(member: member.value)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .room):
                break
                
            case (.room, .presentMessageForwarding(let eventID), .messageForwarding):
                presentMessageForwarding(for: eventID)
            case (.messageForwarding, .dismissMessageForwarding, .room):
                break
            case (.room, .presentMapNavigator(let mode), .mapNavigator):
                presentMapNavigator(interactionMode: mode)
            case (.mapNavigator, .dismissMapNavigator, .room):
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
            fatalError("Failed transition with context: \(context)")
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
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func asyncPresentRoom(_ roomID: String, animated: Bool, destinationRoomProxy: RoomProxyProtocol? = nil) async {
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
        
        actionsSubject.send(.presentedRoom(roomID))
        
        self.roomProxy = roomProxy
        
        let userId = userSession.clientProxy.userID
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userId,
                                                          mediaProvider: userSession.mediaProvider,
                                                          attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: appSettings.permalinkBaseURL),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userId))
        
        let timelineController = roomTimelineControllerFactory.buildRoomTimelineController(userId: userId,
                                                                                           roomProxy: roomProxy,
                                                                                           timelineItemFactory: timelineItemFactory,
                                                                                           mediaProvider: userSession.mediaProvider)
        self.timelineController = timelineController
        
        analytics.trackViewRoom(isDM: roomProxy.isDirect, isSpace: roomProxy.isSpace)
        
        let parameters = RoomScreenCoordinatorParameters(roomProxy: roomProxy,
                                                         timelineController: timelineController,
                                                         mediaProvider: userSession.mediaProvider,
                                                         emojiProvider: emojiProvider)
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
                case .presentEmojiPicker(let itemID):
                    stateMachine.tryEvent(.presentEmojiPicker(itemID: itemID))
                case .presentLocationPicker:
                    stateMachine.tryEvent(.presentMapNavigator(interactionMode: .picker))
                case .presentLocationViewer(_, let geoURI, let description):
                    stateMachine.tryEvent(.presentMapNavigator(interactionMode: .viewOnly(geoURI: geoURI, description: description)))
                case .presentRoomMemberDetails(member: let member):
                    stateMachine.tryEvent(.presentRoomMemberDetails(member: .init(value: member)))
                case .presentMessageForwarding(let itemID):
                    stateMachine.tryEvent(.presentMessageForwarding(itemID: itemID))
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
        // Setting the detail coordinator to nil afirst allows the dismiss to work properly
        // if followed immediately by another navigation on iPhone
        navigationSplitCoordinator.setDetailCoordinator(nil, animated: animated)
        navigationStackCoordinator.popToRoot(animated: false)
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
        } else {
            await asyncPresentRoom(roomID, animated: animated)
        }
        
        guard let roomProxy else {
            MXLog.error("Invalid room identifier: \(roomID)")
            stateMachine.tryEvent(.dismissRoom)
            return
        }
        
        let params = RoomDetailsScreenCoordinatorParameters(accountUserID: userSession.userID,
                                                            navigationStackCoordinator: navigationStackCoordinator,
                                                            roomProxy: roomProxy,
                                                            mediaProvider: userSession.mediaProvider,
                                                            userDiscoveryService: UserDiscoveryService(clientProxy: userSession.clientProxy),
                                                            userIndicatorController: userIndicatorController)
        let coordinator = RoomDetailsScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case .leftRoom:
                self?.dismissRoom(animated: animated)
            }
        }
        
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
    
    private func presentReportContent(for itemID: String, from senderID: String) {
        guard let roomProxy else {
            fatalError()
        }
        
        let navigationCoordinator = NavigationStackCoordinator()
        let userIndicatorController = UserIndicatorController(rootCoordinator: navigationCoordinator)
        let parameters = ReportContentScreenCoordinatorParameters(itemID: itemID,
                                                                  senderID: senderID,
                                                                  roomProxy: roomProxy,
                                                                  userIndicatorController: userIndicatorController)
        let coordinator = ReportContentScreenCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] completion in
            self?.navigationStackCoordinator.setSheetCoordinator(nil)
            
            switch completion {
            case .cancel:
                break
            case .finish:
                userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonReportSubmitted, iconName: "checkmark"))
            }
        }
        navigationCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(userIndicatorController) { [weak self] in
            self?.stateMachine.tryEvent(.dismissReportContent)
        }
    }
    
    private func presentMediaUploadPickerWithSource(_ source: MediaPickerScreenSource) {
        let stackCoordinator = NavigationStackCoordinator()
        let userIndicatorController = UserIndicatorController(rootCoordinator: stackCoordinator)

        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: userIndicatorController, source: source) { [weak self] action in
            switch action {
            case .cancel:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            case .selectMediaAtURL(let url):
                self?.stateMachine.tryEvent(.presentMediaUploadPreview(fileURL: url))
            }
        }

        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)

        navigationStackCoordinator.setSheetCoordinator(userIndicatorController) { [weak self] in
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
        let userIndicatorController = UserIndicatorController(rootCoordinator: stackCoordinator)

        let parameters = MediaUploadPreviewScreenCoordinatorParameters(userIndicatorController: userIndicatorController,
                                                                       roomProxy: roomProxy,
                                                                       mediaUploadingPreprocessor: MediaUploadingPreprocessor(),
                                                                       title: url.lastPathComponent,
                                                                       url: url)

        let mediaUploadPreviewScreenCoordinator = MediaUploadPreviewScreenCoordinator(parameters: parameters) { [weak self] action in
            switch action {
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }

        stackCoordinator.setRootCoordinator(mediaUploadPreviewScreenCoordinator)

        navigationStackCoordinator.setSheetCoordinator(userIndicatorController) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMediaUploadPreview)
        }
    }
    
    private func presentEmojiPicker(for itemId: String) {
        let params = EmojiPickerScreenCoordinatorParameters(emojiProvider: emojiProvider,
                                                            itemId: itemId)
        let coordinator = EmojiPickerScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case let .emojiSelected(emoji: emoji, itemId: itemId):
                MXLog.debug("Selected \(emoji) for \(itemId)")
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
                Task {
                    await self?.timelineController?.toggleReaction(emoji, to: itemId)
                }
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        
        navigationStackCoordinator.setSheetCoordinator(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissEmojiPicker)
        }
    }

    private func presentMapNavigator(interactionMode: StaticLocationInteractionMode) {
        let locationPickerNavigationStackCoordinator = NavigationStackCoordinator()

        let params = StaticLocationScreenCoordinatorParameters(interactionMode: interactionMode)
        let coordinator = StaticLocationScreenCoordinator(parameters: params)

        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .selectedLocation(let geoURI, let isUserLocation):
                Task {
                    _ = await self.roomProxy?.sendLocation(body: geoURI.bodyMessage,
                                                           geoURI: geoURI,
                                                           description: nil,
                                                           zoomLevel: nil,
                                                           assetType: isUserLocation ? .sender : .pin)
                    self.navigationSplitCoordinator.setSheetCoordinator(nil)
                }
                
                self.analytics.trackComposer(inThread: false,
                                             isEditing: false,
                                             isLocation: true,
                                             isReply: false,
                                             locationType: isUserLocation ? .MyLocation : .PinDrop,
                                             startsThread: nil)
            case .close:
                self.navigationSplitCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)

        locationPickerNavigationStackCoordinator.setRootCoordinator(coordinator)

        navigationStackCoordinator.setSheetCoordinator(locationPickerNavigationStackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMapNavigator)
        }
    }
    
    private func presentRoomMemberDetails(member: RoomMemberProxyProtocol) {
        let params = RoomMemberDetailsScreenCoordinatorParameters(roomMemberProxy: member, mediaProvider: userSession.mediaProvider)
        let coordinator = RoomMemberDetailsScreenCoordinator(parameters: params)

        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomMemberDetails)
        }
    }
    
    private func presentMessageForwarding(for eventID: String) {
        guard let roomProxy, let roomSummaryProvider = userSession.clientProxy.roomSummaryProvider else {
            fatalError()
        }
        
        let messageForwardingNavigationStackCoordinator = NavigationStackCoordinator()
        
        let parameters = MessageForwardingScreenCoordinatorParameters(roomSummaryProvider: roomSummaryProvider,
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
        
        messageForwardingNavigationStackCoordinator.setRootCoordinator(coordinator)

        navigationStackCoordinator.setSheetCoordinator(messageForwardingNavigationStackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMessageForwarding)
        }
    }
    
    private func forward(eventID: String, toRoomID roomID: String) async {
        guard let roomProxy else {
            MXLog.error("Failed retrieving current room with id: \(roomID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        guard let messageEventContent = roomProxy.messageEventContent(for: eventID) else {
            MXLog.error("Failed retrieving forwarded message event content for eventID: \(eventID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        guard let targetRoomProxy = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Failed retrieving room to forward to with id: \(roomID)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        if case .failure(let error) = await targetRoomProxy.sendMessageEventContent(messageEventContent) {
            MXLog.error("Failed forwarding message with error: \(error)")
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            return
        }
        
        stateMachine.tryEvent(.presentRoom(roomID: roomID), userInfo: EventUserInfo(animated: true, destinationRoomProxy: targetRoomProxy))
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
        case reportContent(roomID: String, itemID: String, senderID: String)
        case roomDetails(roomID: String, isRoot: Bool)
        case mediaUploadPicker(roomID: String, source: MediaPickerScreenSource)
        case mediaUploadPreview(roomID: String, fileURL: URL)
        case emojiPicker(roomID: String, itemID: String)
        case mapNavigator(roomID: String)
        case roomMemberDetails(roomID: String, member: HashableRoomMemberWrapper)
        case messageForwarding(roomID: String, itemID: String)
    }
    
    struct EventUserInfo {
        let animated: Bool
        var destinationRoomProxy: RoomProxyProtocol?
    }

    enum Event: EventType {
        case presentRoom(roomID: String)
        case dismissRoom
        
        case presentReportContent(itemID: String, senderID: String)
        case dismissReportContent
        
        case presentRoomDetails(roomID: String)
        case dismissRoomDetails
                
        case presentMediaUploadPicker(source: MediaPickerScreenSource)
        case dismissMediaUploadPicker
        
        case presentMediaUploadPreview(fileURL: URL)
        case dismissMediaUploadPreview
        
        case presentEmojiPicker(itemID: String)
        case dismissEmojiPicker

        case presentMapNavigator(interactionMode: StaticLocationInteractionMode)
        case dismissMapNavigator
        
        case presentRoomMemberDetails(member: HashableRoomMemberWrapper)
        case dismissRoomMemberDetails
        
        case presentMessageForwarding(itemID: String)
        case dismissMessageForwarding
    }
}

private extension GeoURI {
    var bodyMessage: String {
        String(format: "Location was shared at %@ as of %@", string, Date().description)
    }
}
