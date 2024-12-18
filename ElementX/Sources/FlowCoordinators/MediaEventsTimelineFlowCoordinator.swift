//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum MediaEventsTimelineFlowCoordinatorAction {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case finished
}

class MediaEventsTimelineFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let userSession: UserSessionProtocol
    private let roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let emojiProvider: EmojiProviderProtocol
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationStackCoordinator: NavigationStackCoordinator,
         userSession: UserSessionProtocol,
         roomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol,
         roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         emojiProvider: EmojiProviderProtocol) {
        self.navigationStackCoordinator = navigationStackCoordinator
        self.userSession = userSession
        self.roomTimelineControllerFactory = roomTimelineControllerFactory
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.emojiProvider = emojiProvider
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
                                                          stateEventStringBuilder: RoomStateEventStringBuilder(userID: userSession.clientProxy.userID))
        
        guard case let .success(mediaTimelineController) = await roomTimelineControllerFactory.buildMessageFilteredRoomTimelineController(allowedMessageTypes: [.image, .video],
                                                                                                                                          roomProxy: roomProxy,
                                                                                                                                          timelineItemFactory: timelineItemFactory,
                                                                                                                                          mediaProvider: userSession.mediaProvider) else {
            MXLog.error("Failed presenting media timeline")
            return
        }
        
        guard case let .success(filesTimelineController) = await roomTimelineControllerFactory.buildMessageFilteredRoomTimelineController(allowedMessageTypes: [.file, .audio],
                                                                                                                                          roomProxy: roomProxy,
                                                                                                                                          timelineItemFactory: timelineItemFactory,
                                                                                                                                          mediaProvider: userSession.mediaProvider) else {
            MXLog.error("Failed presenting media timeline")
            return
        }
        
        let parameters = MediaEventsTimelineScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                        mediaTimelineController: mediaTimelineController,
                                                                        filesTimelineController: filesTimelineController,
                                                                        mediaProvider: userSession.mediaProvider,
                                                                        mediaPlayerProvider: MediaPlayerProvider(),
                                                                        voiceMessageMediaManager: userSession.voiceMessageMediaManager,
                                                                        appMediator: appMediator,
                                                                        emojiProvider: emojiProvider,
                                                                        userIndicatorController: userIndicatorController)
        
        let coordinator = MediaEventsTimelineScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                switch action {
                case .viewItem(let previewContext):
                    self?.presentMediaPreview(for: previewContext)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
    
    private func presentMediaPreview(for previewContext: TimelineMediaPreviewContext) {
        let parameters = TimelineMediaPreviewCoordinatorParameters(context: previewContext,
                                                                   mediaProvider: userSession.mediaProvider,
                                                                   userIndicatorController: userIndicatorController,
                                                                   appMediator: appMediator)
        
        let coordinator = TimelineMediaPreviewCoordinator(parameters: parameters)
        coordinator.actionsPublisher
            .sink { [weak self] action in
                switch action {
                case .viewInRoomTimeline(let itemID):
                    self?.navigationStackCoordinator.pop(animated: false)
                    self?.actionsSubject.send(.viewInRoomTimeline(itemID))
                    self?.navigationStackCoordinator.setFullScreenCoverCoordinator(nil)
                case .dismiss:
                    self?.navigationStackCoordinator.setFullScreenCoverCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setFullScreenCoverCoordinator(coordinator)
    }
}
