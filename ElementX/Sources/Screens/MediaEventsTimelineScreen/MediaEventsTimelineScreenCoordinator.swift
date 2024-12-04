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
    let imageAndVideoTimelineController: RoomTimelineControllerProtocol
    let fileAndAudioTimelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let appMediator: AppMediatorProtocol
    let emojiProvider: EmojiProviderProtocol
}

enum MediaEventsTimelineScreenCoordinatorAction {
    case dismiss
    case displayUser(userID: String)
    case presentLocationViewer(geoURI: GeoURI, description: String?)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayRoomScreenWithFocussedPin(eventID: String)
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
        
        let imageAndVideoTimelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                                               timelineController: parameters.imageAndVideoTimelineController,
                                                               mediaProvider: parameters.mediaProvider,
                                                               mediaPlayerProvider: parameters.mediaPlayerProvider,
                                                               voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                               appMediator: parameters.appMediator,
                                                               appSettings: ServiceLocator.shared.settings,
                                                               analyticsService: ServiceLocator.shared.analytics,
                                                               emojiProvider: parameters.emojiProvider)
        
        let fileAndAudioTimelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                                              timelineController: parameters.fileAndAudioTimelineController,
                                                              mediaProvider: parameters.mediaProvider,
                                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                                              voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                              appMediator: parameters.appMediator,
                                                              appSettings: ServiceLocator.shared.settings,
                                                              analyticsService: ServiceLocator.shared.analytics,
                                                              emojiProvider: parameters.emojiProvider)
        
        viewModel = MediaEventsTimelineScreenViewModel(imageAndVideoTimelineViewModel: imageAndVideoTimelineViewModel,
                                                       fileAndAudioTimelineViewModel: fileAndAudioTimelineViewModel,
                                                       mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            default:
                break
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(MediaEventsTimelineScreen(context: viewModel.context))
    }
}
