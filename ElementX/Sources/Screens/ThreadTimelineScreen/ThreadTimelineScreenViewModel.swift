//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ThreadTimelineScreenViewModelType = StateStoreViewModel<ThreadTimelineScreenViewState, ThreadTimelineScreenViewAction>

class ThreadTimelineScreenViewModel: ThreadTimelineScreenViewModelType, ThreadTimelineScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<ThreadTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ThreadTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: ThreadTimelineScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: ThreadTimelineScreenViewAction) { }
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewViewModel = nil
    }
    
    func displayMediaPreview(_ mediaPreviewViewModel: TimelineMediaPreviewViewModel) {
        mediaPreviewViewModel.actions.sink { [weak self] action in
            switch action {
            case .viewInRoomTimeline:
                fatalError("viewInRoomTimeline should not be visible on a thread preview.")
            case .dismiss:
                self?.state.bindings.mediaPreviewViewModel = nil
            }
        }
        .store(in: &cancellables)
        
        state.bindings.mediaPreviewViewModel = mediaPreviewViewModel
    }
}
