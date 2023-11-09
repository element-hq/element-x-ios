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

struct MediaUploadPreviewScreenCoordinatorParameters {
    let userIndicatorController: UserIndicatorControllerProtocol
    let roomProxy: RoomProxyProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let title: String?
    let url: URL
}

enum MediaUploadPreviewScreenCoordinatorAction {
    case dismiss
}

final class MediaUploadPreviewScreenCoordinator: CoordinatorProtocol {
    private var viewModel: MediaUploadPreviewScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<MediaUploadPreviewScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<MediaUploadPreviewScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: MediaUploadPreviewScreenCoordinatorParameters) {
        viewModel = MediaUploadPreviewScreenViewModel(userIndicatorController: parameters.userIndicatorController,
                                                      roomProxy: parameters.roomProxy,
                                                      mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                      title: parameters.title,
                                                      url: parameters.url)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(MediaUploadPreviewScreen(context: viewModel.context))
    }
}
