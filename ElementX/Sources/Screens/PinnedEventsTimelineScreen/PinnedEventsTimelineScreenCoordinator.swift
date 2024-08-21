//
// Copyright 2022 New Vector Ltd
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
        
        viewModel = PinnedEventsTimelineScreenViewModel()
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              timelineController: parameters.timelineController,
                                              isPinnedEventsTimeline: true,
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
            case .displayEmojiPicker, .displayReportContent, .displayCameraPicker, .displayMediaPicker, .displayDocumentPicker, .displayLocationPicker, .displayPollForm, .displayMediaUploadPreviewScreen, .composer, .hasScrolled:
                break
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: timelineViewModel.context))
    }
}
