//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum MediaEventsTimelineFlowCoordinatorAction {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case finished
}

class MediaEventsTimelineFlowCoordinator: FlowCoordinatorProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    private let zeroAttachmentService: ZeroAttachmentService
    
    private var userSession: UserSessionProtocol { flowParameters.userSession }
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(roomProxy: JoinedRoomProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.roomProxy = roomProxy
        self.navigationStackCoordinator = navigationStackCoordinator
        self.flowParameters = flowParameters
        zeroAttachmentService = ZeroAttachmentService(appSettings: flowParameters.appSettings,
                                                      isRoomEncrypted: roomProxy.infoPublisher.value.isEncrypted)
    }
    
    func start() {
        Task { await presentMediaEventsTimeline() }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func presentMediaEventsTimeline() async {
        let timelineItemFactory = RoomTimelineItemFactory(userID: userSession.clientProxy.userID,
                                                          attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userSession.clientProxy.userID),
                                                          zeroAttachmentService: zeroAttachmentService)
        
        guard case let .success(mediaTimelineController) = await flowParameters.timelineControllerFactory.buildMessageFilteredTimelineController(focus: .live,
                                                                                                                                                 allowedMessageTypes: [.image, .video],
                                                                                                                                                 presentation: .mediaFilesScreen,
                                                                                                                                                 roomProxy: roomProxy,
                                                                                                                                                 timelineItemFactory: timelineItemFactory,
                                                                                                                                                 mediaProvider: userSession.mediaProvider) else {
            MXLog.error("Failed presenting media timeline")
            return
        }
        
        guard case let .success(filesTimelineController) = await flowParameters.timelineControllerFactory.buildMessageFilteredTimelineController(focus: .live,
                                                                                                                                                 allowedMessageTypes: [.file, .audio],
                                                                                                                                                 presentation: .mediaFilesScreen,
                                                                                                                                                 roomProxy: roomProxy,
                                                                                                                                                 timelineItemFactory: timelineItemFactory,
                                                                                                                                                 mediaProvider: userSession.mediaProvider) else {
            MXLog.error("Failed presenting media timeline")
            return
        }
        
        let parameters = MediaEventsTimelineScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                        mediaTimelineController: mediaTimelineController,
                                                                        filesTimelineController: filesTimelineController,
                                                                        userSession: userSession,
                                                                        mediaPlayerProvider: MediaPlayerProvider(),
                                                                        appMediator: flowParameters.appMediator,
                                                                        appSettings: flowParameters.appSettings,
                                                                        analytics: flowParameters.analytics,
                                                                        emojiProvider: flowParameters.emojiProvider,
                                                                        userIndicatorController: flowParameters.userIndicatorController,
                                                                        timelineControllerFactory: flowParameters.timelineControllerFactory)
        
        let coordinator = MediaEventsTimelineScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .viewInRoomTimeline(let itemID):
                    self?.navigationStackCoordinator.pop(animated: false)
                    self?.actionsSubject.send(.viewInRoomTimeline(itemID))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
}
