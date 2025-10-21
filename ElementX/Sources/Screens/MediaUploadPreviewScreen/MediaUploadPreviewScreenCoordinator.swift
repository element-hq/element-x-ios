//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MediaUploadPreviewScreenCoordinatorParameters {
    let mediaURLs: [URL]
    let title: String?
    let isRoomEncrypted: Bool
    let shouldShowCaptionWarning: Bool
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let timelineController: TimelineControllerProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
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
        viewModel = MediaUploadPreviewScreenViewModel(mediaURLs: parameters.mediaURLs,
                                                      title: parameters.title,
                                                      isRoomEncrypted: parameters.isRoomEncrypted,
                                                      shouldShowCaptionWarning: parameters.shouldShowCaptionWarning,
                                                      mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                      timelineController: parameters.timelineController,
                                                      clientProxy: parameters.clientProxy,
                                                      userIndicatorController: parameters.userIndicatorController)
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
