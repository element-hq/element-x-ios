//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct PinnedEventsTimelineScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let timelineController: TimelineControllerProtocol
    let userSession: UserSessionProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
    let emojiProvider: EmojiProviderProtocol
    let linkMetadataProvider: LinkMetadataProviderProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum PinnedEventsTimelineScreenCoordinatorAction {
    case dismiss
    case displayUser(userID: String)
    case presentLocationViewer(geoURI: GeoURI, description: String?)
    case displayMessageForwarding(forwardingItem: MessageForwardingItem)
    case displayRoomScreenWithFocussedPin(eventID: String, threadRootEventID: String?)
}

final class PinnedEventsTimelineScreenCoordinator: CoordinatorProtocol {
    private let viewModel: PinnedEventsTimelineScreenViewModelProtocol
    private let timelineViewModel: TimelineViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<PinnedEventsTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: PinnedEventsTimelineScreenCoordinatorParameters) {
        viewModel = PinnedEventsTimelineScreenViewModel(roomProxy: parameters.roomProxy,
                                                        userIndicatorController: parameters.userIndicatorController,
                                                        appSettings: parameters.appSettings,
                                                        analyticsService: parameters.analytics)
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              timelineController: parameters.timelineController,
                                              userSession: parameters.userSession,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              userIndicatorController: parameters.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: parameters.appSettings,
                                              analyticsService: parameters.analytics,
                                              emojiProvider: parameters.emojiProvider,
                                              linkMetadataProvider: parameters.linkMetadataProvider,
                                              timelineControllerFactory: parameters.timelineControllerFactory)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .displayMessageForwarding(let forwardingItem):
                actionsSubject.send(.displayMessageForwarding(forwardingItem: forwardingItem))
            case .viewInRoomTimeline(let eventID, let threadRootEventID):
                actionsSubject.send(.displayRoomScreenWithFocussedPin(eventID: eventID, threadRootEventID: threadRootEventID))
            case .dismiss:
                self.actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
        
        timelineViewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received timeline view model action: \(action)")
            guard let self else { return }
            
            switch action {
            case .displaySenderDetails(let userID):
                actionsSubject.send(.displayUser(userID: userID))
            case .displayMessageForwarding(let forwardingItem):
                actionsSubject.send(.displayMessageForwarding(forwardingItem: forwardingItem))
            case .displayMediaPreview(let mediaPreviewViewModel):
                viewModel.displayMediaPreview(mediaPreviewViewModel)
            case .displayLocation(_, let geoURI, let description):
                actionsSubject.send(.presentLocationViewer(geoURI: geoURI, description: description))
            case .viewInRoomTimeline(let eventID, let threadRootEventID):
                actionsSubject.send(.displayRoomScreenWithFocussedPin(eventID: eventID, threadRootEventID: threadRootEventID))
            // These other actions will not be handled in this view
            case .displayEmojiPicker, .displayReportContent, .displayCameraPicker, .displayMediaPicker,
                 .displayDocumentPicker, .displayLocationPicker, .displayPollForm, .displayMediaUploadPreviewScreen,
                 .displayResolveSendFailure, .displayThread, .composer, .hasScrolled, .displayRoom, .displayMediaDetails:
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
        AnyView(PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: timelineViewModel.context))
    }
}
