//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum PinnedEventsTimelineFlowCoordinatorAction {
    case finished
    case displayUser(userID: String)
    case forwardedMessageToRoom(roomID: String)
    case displayRoomScreenWithFocussedPin(eventID: String)
}

class PinnedEventsTimelineFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let userSession: UserSessionProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinnedEventsTimelineFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationStackCoordinator: NavigationStackCoordinator,
         userSession: UserSessionProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol) {
        self.navigationStackCoordinator = navigationStackCoordinator
        self.userSession = userSession
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
    }
    
    func start() {
        Task { await presentPinnedEventsTimeline() }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    private func presentPinnedEventsTimeline() async {
        let userID = userSession.clientProxy.userID
        let timelineItemFactory = RoomTimelineItemFactory(userID: userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID))
                
        guard let timelineController = await roomTimelineControllerFactory.buildRoomPinnedTimelineController(roomProxy: roomProxy, timelineItemFactory: timelineItemFactory) else {
            fatalError("This can never fail because we allow this view to be presented only when the timeline is fully loaded and not nil")
        }
        
        let coordinator = PinnedEventsTimelineScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                                  timelineController: timelineController,
                                                                                  mediaProvider: userSession.mediaProvider,
                                                                                  mediaPlayerProvider: MediaPlayerProvider(),
                                                                                  voiceMessageMediaManager: userSession.voiceMessageMediaManager,
                                                                                  appMediator: appMediator))
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.finished)
                case .displayUser(let userID):
                    actionsSubject.send(.displayUser(userID: userID))
                case .presentLocationViewer(let geoURI, let description):
                    presentMapNavigator(geoURI: geoURI, description: description)
                case .displayMessageForwarding(let forwardingItem):
                    presentMessageForwarding(with: forwardingItem)
                case .displayRoomScreenWithFocussedPin(let eventID):
                    actionsSubject.send(.displayRoomScreenWithFocussedPin(eventID: eventID))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentMapNavigator(geoURI: GeoURI, description: String?) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let params = StaticLocationScreenCoordinatorParameters(interactionMode: .viewOnly(geoURI: geoURI, description: description), appMediator: appMediator)
        let coordinator = StaticLocationScreenCoordinator(parameters: params)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .selectedLocation:
                // We don't handle the sending/picker case in this flow
                break
            case .close:
                self.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator)
    }
    
    private func presentMessageForwarding(with forwardingItem: MessageForwardingItem) {
        guard let roomSummaryProvider = userSession.clientProxy.alternateRoomSummaryProvider else {
            fatalError()
        }
        
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
                actionsSubject.send(.forwardedMessageToRoom(roomID: roomID))
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)

        navigationStackCoordinator.setSheetCoordinator(stackCoordinator)
    }
}
