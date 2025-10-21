//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MediaEventsTimelineScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let mediaTimelineController: TimelineControllerProtocol
    let filesTimelineController: TimelineControllerProtocol
    let userSession: UserSessionProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
    let emojiProvider: EmojiProviderProtocol
    let linkMetadataProvider: LinkMetadataProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
}

enum MediaEventsTimelineScreenCoordinatorAction {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case displayMessageForwarding(MessageForwardingItem)
}

final class MediaEventsTimelineScreenCoordinator: CoordinatorProtocol {
    private let parameters: MediaEventsTimelineScreenCoordinatorParameters
    private let viewModel: MediaEventsTimelineScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<MediaEventsTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: MediaEventsTimelineScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let mediaTimelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                                       timelineController: parameters.mediaTimelineController,
                                                       userSession: parameters.userSession,
                                                       mediaPlayerProvider: parameters.mediaPlayerProvider,
                                                       userIndicatorController: parameters.userIndicatorController,
                                                       appMediator: parameters.appMediator,
                                                       appSettings: parameters.appSettings,
                                                       analyticsService: parameters.analytics,
                                                       emojiProvider: parameters.emojiProvider,
                                                       linkMetadataProvider: parameters.linkMetadataProvider,
                                                       timelineControllerFactory: parameters.timelineControllerFactory)
        
        let filesTimelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                                       timelineController: parameters.filesTimelineController,
                                                       userSession: parameters.userSession,
                                                       mediaPlayerProvider: parameters.mediaPlayerProvider,
                                                       userIndicatorController: parameters.userIndicatorController,
                                                       appMediator: parameters.appMediator,
                                                       appSettings: parameters.appSettings,
                                                       analyticsService: parameters.analytics,
                                                       emojiProvider: parameters.emojiProvider,
                                                       linkMetadataProvider: parameters.linkMetadataProvider,
                                                       timelineControllerFactory: parameters.timelineControllerFactory)
        
        viewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: mediaTimelineViewModel,
                                                       filesTimelineViewModel: filesTimelineViewModel,
                                                       mediaProvider: parameters.userSession.mediaProvider,
                                                       userIndicatorController: parameters.userIndicatorController,
                                                       appMediator: parameters.appMediator)
        
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.displayMessageForwarding(forwardingItem))
                case .viewInRoomTimeline(let itemID):
                    actionsSubject.send(.viewInRoomTimeline(itemID))
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(MediaEventsTimelineScreen(context: viewModel.context))
    }
}
