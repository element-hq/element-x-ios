//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum MediaEventsTimelineFlowCoordinatorAction {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case displayMessageForwarding(MessageForwardingItem)
    case finished
}

class MediaEventsTimelineFlowCoordinator: FlowCoordinatorProtocol {
    typealias Controllers = (media: TimelineControllerProtocol, files: TimelineControllerProtocol)
    
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    private let prebuiltControllers: Task<Controllers?, Never>?
    
    private var userSession: UserSessionProtocol {
        flowParameters.userSession
    }
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// - Parameter prebuiltControllers: the timelines built ahead (see ``buildControllers``), so
    ///   that the screen opens as soon as it's asked for.
    init(roomProxy: JoinedRoomProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters,
         prebuiltControllers: Task<Controllers?, Never>? = nil) {
        self.roomProxy = roomProxy
        self.navigationStackCoordinator = navigationStackCoordinator
        self.flowParameters = flowParameters
        self.prebuiltControllers = prebuiltControllers
    }
    
    /// Builds the media and files timelines of the room, which takes a while for a media-heavy
    /// room (the store is walked for the room's media messages): call it ahead of the tap.
    static func buildControllers(roomProxy: JoinedRoomProxyProtocol, flowParameters: CommonFlowParameters) -> Task<Controllers?, Never> {
        Task {
            let userSession = flowParameters.userSession
            let timelineItemFactory = RoomTimelineItemFactory(userID: userSession.clientProxy.userID,
                                                              attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: userSession.clientProxy.userID))
            
            let media = await flowParameters.timelineControllerFactory.buildMessageFilteredTimelineController(focus: .messageTypes(),
                                                                                                            allowedMessageTypes: [.image, .video, .gallery],
                                                                                                             presentation: .mediaFilesScreen,
                                                                                                             roomProxy: roomProxy,
                                                                                                             timelineItemFactory: timelineItemFactory,
                                                                                                             mediaProvider: userSession.mediaProvider)
            let files = await flowParameters.timelineControllerFactory.buildMessageFilteredTimelineController(focus: .messageTypes(),
                                                                                                            allowedMessageTypes: [.file, .audio, .gallery],
                                                                                                             presentation: .mediaFilesScreen,
                                                                                                             roomProxy: roomProxy,
                                                                                                             timelineItemFactory: timelineItemFactory,
                                                                                                             mediaProvider: userSession.mediaProvider)
            guard case .success(let mediaTimelineController) = media,
                  case .success(let filesTimelineController) = files else {
                MXLog.error("Failed building the media and files timelines")
                return nil
            }
            return (mediaTimelineController, filesTimelineController)
        }
    }
    
    func start(animated: Bool) {
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
        let controllers = prebuiltControllers ?? Self.buildControllers(roomProxy: roomProxy, flowParameters: flowParameters)
        guard let (mediaTimelineController, filesTimelineController) = await controllers.value else {
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
                                                                        linkMetadataProvider: flowParameters.linkMetadataProvider,
                                                                        userIndicatorController: flowParameters.userIndicatorController,
                                                                        timelineControllerFactory: flowParameters.timelineControllerFactory)
        
        let coordinator = MediaEventsTimelineScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.displayMessageForwarding(forwardingItem))
                case .viewInRoomTimeline(let itemID):
                    navigationStackCoordinator.pop(animated: false)
                    actionsSubject.send(.viewInRoomTimeline(itemID))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
}
