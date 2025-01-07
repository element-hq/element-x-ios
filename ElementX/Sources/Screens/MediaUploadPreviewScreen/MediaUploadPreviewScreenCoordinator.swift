//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MediaUploadPreviewScreenCoordinatorParameters {
    let userIndicatorController: UserIndicatorControllerProtocol
    let roomProxy: JoinedRoomProxyProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let title: String?
    let url: URL
    let shouldShowCaptionWarning: Bool
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
                                                      url: parameters.url,
                                                      shouldShowCaptionWarning: parameters.shouldShowCaptionWarning)
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
    
    func stop() {
        viewModel.stopProcessing()
    }
    
    func toPresentable() -> AnyView {
        AnyView(MediaUploadPreviewScreen(context: viewModel.context))
    }
}
