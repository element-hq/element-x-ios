//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias MediaEventsTimelineScreenViewModelType = StateStoreViewModel<MediaEventsTimelineScreenViewState, MediaEventsTimelineScreenViewAction>

class MediaEventsTimelineScreenViewModel: MediaEventsTimelineScreenViewModelType, MediaEventsTimelineScreenViewModelProtocol {
    private let imageAndVideoTimelineViewModel: TimelineViewModelProtocol
    private let fileAndAudioTimelineViewModel: TimelineViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(imageAndVideoTimelineViewModel: TimelineViewModelProtocol,
         fileAndAudioTimelineViewModel: TimelineViewModelProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.imageAndVideoTimelineViewModel = imageAndVideoTimelineViewModel
        self.fileAndAudioTimelineViewModel = fileAndAudioTimelineViewModel
        
        super.init(initialViewState: .init(bindings: .init()), mediaProvider: mediaProvider)
        
        imageAndVideoTimelineViewModel.context.$viewState.sink { [weak self] _ in
            self?.updateFromTimelineViewState()
        }
        .store(in: &cancellables)
        
        updateFromTimelineViewState()
    }
    
    // MARK: - Public
    
    override func process(viewAction: MediaEventsTimelineScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .changedScreenMode:
            updateFromTimelineViewState()
        case .changedTopMostVisibleItem:
            break
        }
    }
    
    // MARK: - Private
    
    private func updateFromTimelineViewState() {
        let timelineViewState = activeTimelineViewModel.context.viewState
        
        #warning("This is some funky naming right here")
        state.items = timelineViewState.timelineViewState.itemViewStates
        state.isBackPaginating = (timelineViewState.timelineViewState.paginationState.backward == .paginating)
    }
    
    private var activeTimelineViewModel: TimelineViewModelProtocol {
        switch state.bindings.screenMode {
        case .imageAndVideo:
            imageAndVideoTimelineViewModel
        case .fileAndAudio:
            fileAndAudioTimelineViewModel
        }
    }
}
