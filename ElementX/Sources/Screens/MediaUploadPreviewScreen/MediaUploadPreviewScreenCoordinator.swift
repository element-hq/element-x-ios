//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MediaUploadPreviewScreenCoordinatorParameters {
    let timelineController: TimelineControllerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let title: String?
    let url: URL
    let shouldShowCaptionWarning: Bool
    let isRoomEncrypted: Bool
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
        viewModel = MediaUploadPreviewScreenViewModel(timelineController: parameters.timelineController,
                                                      userIndicatorController: parameters.userIndicatorController,
                                                      mediaUploadingPreprocessor: parameters.mediaUploadingPreprocessor,
                                                      title: parameters.title,
                                                      url: parameters.url,
                                                      shouldShowCaptionWarning: parameters.shouldShowCaptionWarning,
                                                      isRoomEncrypted: parameters.isRoomEncrypted)
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
