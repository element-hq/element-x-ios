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
    case presentMediaViewer(file: MediaFileHandleProxy, title: String?)
    case presentReportContent(itemID: String, senderID: String)
    case presentMediaUploadPicker(MediaPickerScreenSource)
    case presentMediaUploadPreviewScreen(URL)
    case presentRoomDetails
    case presentEmojiPicker(itemID: String)
    case presentRoomMemberDetails(member: RoomMemberProxyProtocol)
    case presentMessageForwarding(itemID: String)
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private var parameters: RoomScreenCoordinatorParameters

    private var viewModel: RoomScreenViewModelProtocol

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
    }
    
    // MARK: - Public
    
    // swiftlint:disable:next cyclomatic_complexity
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .displayRoomDetails:
                actionsSubject.send(.presentRoomDetails)
            case .displayMediaViewer(let file, let title):
                actionsSubject.send(.presentMediaViewer(file: file, title: title))
            case .displayEmojiPicker(let itemID):
                actionsSubject.send(.presentEmojiPicker(itemID: itemID))
            case .displayReportContent(let itemID, let senderID):
                actionsSubject.send(.presentReportContent(itemID: itemID, senderID: senderID))
            case .displayCameraPicker:
                actionsSubject.send(.presentMediaUploadPicker(.camera))
            case .displayMediaPicker:
                actionsSubject.send(.presentMediaUploadPicker(.photoLibrary))
            case .displayDocumentPicker:
                actionsSubject.send(.presentMediaUploadPicker(.documents))
            case .displayMediaUploadPreviewScreen(let url):
                actionsSubject.send(.presentMediaUploadPreviewScreen(url))
            case .displayRoomMemberDetails(let member):
                actionsSubject.send(.presentRoomMemberDetails(member: member))
            case .displayMessageForwarding(let itemID):
                actionsSubject.send(.presentMessageForwarding(itemID: itemID))
            }
        }
    }
    
    func stop() {
        viewModel.context.send(viewAction: .markRoomAsRead)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomScreen(context: viewModel.context))
    }
}
