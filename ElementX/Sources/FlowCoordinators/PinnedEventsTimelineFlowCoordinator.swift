//
// Copyright 2024 New Vector Ltd
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

enum PinnedEventsTimelineFlowCoordinatorAction {
    case finished
    case displayUser(userID: String)
}

class PinnedEventsTimelineFlowCoordinator: FlowCoordinatorProtocol {
    private let stackCoordinator: NavigationStackCoordinator
    private let userSession: UserSessionProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let roomProxy: RoomProxyProtocol
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinnedEventsTimelineFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(stackCoordinator: NavigationStackCoordinator,
         userSession: UserSessionProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         roomProxy: RoomProxyProtocol,
         appMediator: AppMediatorProtocol) {
        self.stackCoordinator = stackCoordinator
        self.userSession = userSession
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.roomProxy = roomProxy
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
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
    }
}
