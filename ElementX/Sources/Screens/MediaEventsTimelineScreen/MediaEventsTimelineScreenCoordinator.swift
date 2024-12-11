//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct MediaEventsTimelineScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let mediaTimelineController: RoomTimelineControllerProtocol
    let filesTimelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let appMediator: AppMediatorProtocol
    let emojiProvider: EmojiProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum MediaEventsTimelineScreenCoordinatorAction {
    case viewInRoomTimeline(TimelineItemIdentifier)
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
                                                       mediaProvider: parameters.mediaProvider,
                                                       mediaPlayerProvider: parameters.mediaPlayerProvider,
                                                       voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                       appMediator: parameters.appMediator,
                                                       appSettings: ServiceLocator.shared.settings,
                                                       analyticsService: ServiceLocator.shared.analytics,
                                                       emojiProvider: parameters.emojiProvider)
        
        let filesTimelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                                       timelineController: parameters.filesTimelineController,
                                                       mediaProvider: parameters.mediaProvider,
                                                       mediaPlayerProvider: parameters.mediaPlayerProvider,
                                                       voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                       appMediator: parameters.appMediator,
                                                       appSettings: ServiceLocator.shared.settings,
                                                       analyticsService: ServiceLocator.shared.analytics,
                                                       emojiProvider: parameters.emojiProvider)
        
        viewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: mediaTimelineViewModel,
                                                       filesTimelineViewModel: filesTimelineViewModel,
                                                       mediaProvider: parameters.mediaProvider,
                                                       userIndicatorController: parameters.userIndicatorController)
        
        viewModel.actionsPublisher
            .sink { [weak self] action in
                switch action {
                case .viewInRoomTimeline(let itemID):
                    self?.actionsSubject.send(.viewInRoomTimeline(itemID))
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(MediaEventsTimelineScreen(context: viewModel.context))
    }
}
