//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ThreadTimelineScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let timelineController: TimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let appMediator: AppMediatorProtocol
    let emojiProvider: EmojiProviderProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
    let clientProxy: ClientProxyProtocol
}

enum ThreadTimelineScreenCoordinatorAction {
    case dismiss
    case displayUser(userID: String)
    case presentLocationViewer(geoURI: GeoURI, description: String?)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayRoomScreenWithFocussedPin(eventID: String)
}

final class ThreadTimelineScreenCoordinator: CoordinatorProtocol {
    private let parameters: ThreadTimelineScreenCoordinatorParameters
    private let viewModel: ThreadTimelineScreenViewModelProtocol
    private let timelineViewModel: TimelineViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ThreadTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<ThreadTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ThreadTimelineScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ThreadTimelineScreenViewModel()
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              timelineController: parameters.timelineController,
                                              mediaProvider: parameters.mediaProvider,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: ServiceLocator.shared.settings,
                                              analyticsService: ServiceLocator.shared.analytics,
                                              emojiProvider: parameters.emojiProvider,
                                              timelineControllerFactory: parameters.timelineControllerFactory,
                                              clientProxy: parameters.clientProxy)
    }
    
    func start() {
        timelineViewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received timeline view model action: \(action)")
            guard let self else { return }
            
            switch action {
            case .displaySenderDetails(let userID):
                actionsSubject.send(.displayUser(userID: userID))
            case .displayMessageForwarding(let forwardingItem):
                actionsSubject.send(.displayMessageForwarding(forwardingItem: forwardingItem))
            case .displayLocation(_, let geoURI, let description):
                actionsSubject.send(.presentLocationViewer(geoURI: geoURI, description: description))
            case .viewInRoomTimeline(let eventID):
                actionsSubject.send(.displayRoomScreenWithFocussedPin(eventID: eventID))
            // These other actions will not be handled in this view
            case .displayEmojiPicker, .displayReportContent, .displayCameraPicker, .displayMediaPicker,
                 .displayDocumentPicker, .displayLocationPicker, .displayPollForm, .displayMediaPreview,
                 .displayMediaUploadPreviewScreen, .displayResolveSendFailure, .displayThread, .composer, .hasScrolled:
                // These actions are not handled in this coordinator
                break
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(ThreadTimelineScreen(context: viewModel.context, timelineContext: timelineViewModel.context))
    }
}
