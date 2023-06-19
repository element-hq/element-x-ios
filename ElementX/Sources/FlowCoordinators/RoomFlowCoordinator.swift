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
         emojiProvider: EmojiProviderProtocol) {
        self.userSession = userSession
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.navigationStackCoordinator = navigationStackCoordinator
        self.navigationSplitCoordinator = navigationSplitCoordinator
        self.emojiProvider = emojiProvider
        
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
                
            case (.presentMediaViewer(let file, let title), .room(let roomID)):
                return .mediaViewer(roomID: roomID, file: file, title: title)
            case (.dismissMediaViewer, .mediaViewer(let roomID, _, _)):
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
                presentRoom(roomID, animated: animated)
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
                
            case (.room, .presentMediaViewer, .mediaViewer(_, let file, let title)):
                presentMediaViewer(file, title: title)
            case (.mediaViewer, .dismissMediaViewer, .room):
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
                
            case (.room, .presentEmojiPicker, .emojiPicker(_, let itemID)):
                presentEmojiPicker(for: itemID)
            case (.emojiPicker, .dismissEmojiPicker, .room):
                break

            case (.room, .presentRoomMemberDetails, .roomMemberDetails(_, let member)):
                presentRoomMemberDetails(member: member.value)
            case (.roomMemberDetails, .dismissRoomMemberDetails, .room):
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
    
    private func presentRoom(_ roomID: String, animated: Bool) {
        Task {
            await asyncPresentRoom(roomID, animated: animated)
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func asyncPresentRoom(_ roomID: String, animated: Bool) async {
        if let roomProxy, roomProxy.id == roomID {
            navigationStackCoordinator.popToRoot()
            return
        }
        
        guard let roomProxy = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Invalid room identifier: \(roomID)")
            stateMachine.tryEvent(.dismissRoom)
            return
        }
        
        actionsSubject.send(.presentedRoom(roomID))
        
        self.roomProxy = roomProxy
        
        let userId = userSession.clientProxy.userID
        
        let timelineItemFactory = RoomTimelineItemFactory(userID: userId,
                                                          mediaProvider: userSession.mediaProvider,
                                                          attributedStringBuilder: AttributedStringBuilder(),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userId))
        
        let timelineController = roomTimelineControllerFactory.buildRoomTimelineController(userId: userId,
                                                                                           roomProxy: roomProxy,
                                                                                           timelineItemFactory: timelineItemFactory,
                                                                                           mediaProvider: userSession.mediaProvider)
        self.timelineController = timelineController
        
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
                case .presentMediaViewer(let file, let title):
                    stateMachine.tryEvent(.presentMediaViewer(file: file, title: title))
                case .presentReportContent(let itemID, let senderID):
                    stateMachine.tryEvent(.presentReportContent(itemID: itemID, senderID: senderID))
                case .presentMediaUploadPicker(let source):
                    stateMachine.tryEvent(.presentMediaUploadPicker(source: source))
                case .presentMediaUploadPreviewScreen(let url):
                    stateMachine.tryEvent(.presentMediaUploadPreview(fileURL: url))
                case .presentEmojiPicker(let itemID):
                    stateMachine.tryEvent(.presentEmojiPicker(itemID: itemID))
                case .presentRoomMemberDetails(member: let member):
                    stateMachine.tryEvent(.presentRoomMemberDetails(member: .init(value: member)))
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
                                                            userDiscoveryService: UserDiscoveryService(clientProxy: userSession.clientProxy))
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
    
    private func presentMediaViewer(_ file: MediaFileHandleProxy, title: String?) {
        let params = FilePreviewScreenCoordinatorParameters(mediaFile: file, title: title)
        let coordinator = FilePreviewScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case .cancel:
                self?.navigationStackCoordinator.pop()
            }
        }
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissMediaViewer)
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
                self?.showSuccess(label: L10n.commonReportSubmitted)
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
        let emojiPickerNavigationStackCoordinator = NavigationStackCoordinator()

        let params = EmojiPickerScreenCoordinatorParameters(emojiProvider: emojiProvider,
                                                            itemId: itemId)
        let coordinator = EmojiPickerScreenCoordinator(parameters: params)
        coordinator.callback = { [weak self] action in
            switch action {
            case let .emojiSelected(emoji: emoji, itemId: itemId):
                MXLog.debug("Selected \(emoji) for \(itemId)")
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
                Task {
                    await self?.timelineController?.sendReaction(emoji, to: itemId)
                }
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }

        emojiPickerNavigationStackCoordinator.setRootCoordinator(coordinator)
        emojiPickerNavigationStackCoordinator.presentationDetents = [.medium, .large]

        navigationStackCoordinator.setSheetCoordinator(emojiPickerNavigationStackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissEmojiPicker)
        }
    }

    private func presentRoomMemberDetails(member: RoomMemberProxyProtocol) {
        let params = RoomMemberDetailsScreenCoordinatorParameters(roomMemberProxy: member, mediaProvider: userSession.mediaProvider)
        let coordinator = RoomMemberDetailsScreenCoordinator(parameters: params)

        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissRoomMemberDetails)
        }
    }

    private func showSuccess(label: String) {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: label, iconName: "checkmark"))
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
        case mediaViewer(roomID: String, file: MediaFileHandleProxy, title: String?)
        case reportContent(roomID: String, itemID: String, senderID: String)
        case roomDetails(roomID: String, isRoot: Bool)
        case mediaUploadPicker(roomID: String, source: MediaPickerScreenSource)
        case mediaUploadPreview(roomID: String, fileURL: URL)
        case emojiPicker(roomID: String, itemID: String)
        case roomMemberDetails(roomID: String, member: HashableRoomMemberWrapper)
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    enum Event: EventType {
        case presentRoom(roomID: String)
        case dismissRoom
        
        case presentMediaViewer(file: MediaFileHandleProxy, title: String?)
        case dismissMediaViewer
        
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

        case presentRoomMemberDetails(member: HashableRoomMemberWrapper)
        case dismissRoomMemberDetails
    }
}
