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

struct RoomScreenCoordinatorParameters {
    let roomProxy: RoomProxyProtocol
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let emojiProvider: EmojiProviderProtocol
}

enum RoomScreenCoordinatorAction {
    case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case presentMediaUploadPicker(MediaPickerScreenSource)
    case presentMediaUploadPreviewScreen(URL)
    case presentRoomDetails
    case presentLocationPicker
    case presentPollForm
    case presentLocationViewer(body: String, geoURI: GeoURI, description: String?)
    case presentEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case presentRoomMemberDetails(member: RoomMemberProxyProtocol)
    case presentMessageForwarding(itemID: TimelineItemIdentifier)
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private var parameters: RoomScreenCoordinatorParameters
    private var viewModel: RoomScreenViewModelProtocol
    private var composerViewModel: ComposerToolbarViewModel

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<RoomScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomScreenCoordinatorParameters) {
        self.parameters = parameters

        viewModel = RoomScreenViewModel(timelineController: parameters.timelineController,
                                        mediaProvider: parameters.mediaProvider,
                                        roomProxy: parameters.roomProxy,
                                        appSettings: ServiceLocator.shared.settings,
                                        analytics: ServiceLocator.shared.analytics,
                                        userIndicatorController: ServiceLocator.shared.userIndicatorController)

        composerViewModel = ComposerToolbarViewModel()
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .displayRoomDetails:
                    actionsSubject.send(.presentRoomDetails)
                case .displayEmojiPicker(let itemID, let selectedEmojis):
                    actionsSubject.send(.presentEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
                case .displayReportContent(let itemID, let senderID):
                    actionsSubject.send(.presentReportContent(itemID: itemID, senderID: senderID))
                case .displayCameraPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.camera))
                case .displayMediaPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.photoLibrary))
                case .displayDocumentPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.documents))
                case .displayLocationPicker:
                    actionsSubject.send(.presentLocationPicker)
                case .displayPollForm:
                    actionsSubject.send(.presentPollForm)
                case .displayMediaUploadPreviewScreen(let url):
                    actionsSubject.send(.presentMediaUploadPreviewScreen(url))
                case .displayRoomMemberDetails(let member):
                    actionsSubject.send(.presentRoomMemberDetails(member: member))
                case .displayMessageForwarding(let itemID):
                    actionsSubject.send(.presentMessageForwarding(itemID: itemID))
                case .displayLocation(let body, let geoURI, let description):
                    actionsSubject.send(.presentLocationViewer(body: body, geoURI: geoURI, description: description))
                case .composer(let action):
                    composerViewModel.process(roomAction: action)
                }
            }
            .store(in: &cancellables)

        composerViewModel.actions
            .sink { [weak self] composerAction in
                guard let self else { return }

                viewModel.process(composerAction: composerAction)
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomScreen(context: viewModel.context, composerToolbar: ComposerToolbar(context: composerViewModel.context)))
    }
}
