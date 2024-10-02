//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct PinnedEventsTimelineScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let appMediator: AppMediatorProtocol
}

enum PinnedEventsTimelineScreenCoordinatorAction {
    case dismiss
    case displayUser(userID: String)
    case presentLocationViewer(geoURI: GeoURI, description: String?)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayRoomScreenWithFocussedPin(eventID: String)
}

final class PinnedEventsTimelineScreenCoordinator: CoordinatorProtocol {
    private let parameters: PinnedEventsTimelineScreenCoordinatorParameters
    private let viewModel: PinnedEventsTimelineScreenViewModelProtocol
    private let timelineViewModel: TimelineViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<PinnedEventsTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: PinnedEventsTimelineScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = PinnedEventsTimelineScreenViewModel(analyticsService: ServiceLocator.shared.analytics)
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              timelineController: parameters.timelineController,
                                              mediaProvider: parameters.mediaProvider,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: ServiceLocator.shared.settings,
                                              analyticsService: ServiceLocator.shared.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                self.actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
        
        timelineViewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received timeline view model action: \(action)")
            guard let self else { return }
            
            switch action {
            case .tappedOnSenderDetails(let userID):
                actionsSubject.send(.displayUser(userID: userID))
            case .displayMessageForwarding(let forwardingItem):
                actionsSubject.send(.displayMessageForwarding(forwardingItem: forwardingItem))
            case .displayLocation(_, let geoURI, let description):
                actionsSubject.send(.presentLocationViewer(geoURI: geoURI, description: description))
            case .viewInRoomTimeline(let eventID):
                actionsSubject.send(.displayRoomScreenWithFocussedPin(eventID: eventID))
            // These other actions will not be handled in this view
            case .displayEmojiPicker, .displayReportContent, .displayCameraPicker, .displayMediaPicker,
                 .displayDocumentPicker, .displayLocationPicker, .displayPollForm, .displayMediaUploadPreviewScreen,
                 .displayResolveSendFailure, .composer, .hasScrolled:
                // These actions are not handled in this coordinator
                break
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: timelineViewModel.context))
    }
}
