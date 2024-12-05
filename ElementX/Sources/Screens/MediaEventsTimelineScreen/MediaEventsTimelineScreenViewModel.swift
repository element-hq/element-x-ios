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
    
    private var isTopVisible = false
    
    private var activeTimelineViewModel: TimelineViewModelProtocol {
        switch state.bindings.screenMode {
        case .imageAndVideo:
            imageAndVideoTimelineViewModel
        case .fileAndAudio:
            fileAndAudioTimelineViewModel
        }
    }
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(imageAndVideoTimelineViewModel: TimelineViewModelProtocol,
         fileAndAudioTimelineViewModel: TimelineViewModelProtocol,
         mediaProvider: MediaProviderProtocol,
         screenMode: MediaEventsTimelineScreenMode = .imageAndVideo) {
        self.imageAndVideoTimelineViewModel = imageAndVideoTimelineViewModel
        self.fileAndAudioTimelineViewModel = fileAndAudioTimelineViewModel
        
        super.init(initialViewState: .init(bindings: .init(screenMode: screenMode)), mediaProvider: mediaProvider)
        
        imageAndVideoTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.bindings.screenMode == .imageAndVideo else {
                return
            }
            
            updateWithTimelineViewState(timelineViewState)
        }
        .store(in: &cancellables)
        
        fileAndAudioTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.bindings.screenMode == .fileAndAudio else {
                return
            }
            
            updateWithTimelineViewState(timelineViewState)
        }
        .store(in: &cancellables)
        
        updateWithTimelineViewState(activeTimelineViewModel.context.viewState)
    }
    
    // MARK: - Public
    
    override func process(viewAction: MediaEventsTimelineScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .changedScreenMode:
            updateWithTimelineViewState(activeTimelineViewModel.context.viewState)
        case .topBecameVisible:
            isTopVisible = true
            backpaginateIfNecessary(paginationStatus: activeTimelineViewModel.context.viewState.timelineState.paginationState.backward)
        case .topBecameHidden:
            isTopVisible = false
        }
    }
    
    // MARK: - Private
    
    private func updateWithTimelineViewState(_ timelineViewState: TimelineViewState) {
        state.items = timelineViewState.timelineState.itemViewStates.filter { itemViewState in
            switch itemViewState.type {
            case .image, .video:
                state.bindings.screenMode == .imageAndVideo
            case .audio, .file:
                state.bindings.screenMode == .fileAndAudio
            default:
                false
            }
        }.reversed()
        
        state.isBackPaginating = (timelineViewState.timelineState.paginationState.backward == .paginating)
        backpaginateIfNecessary(paginationStatus: timelineViewState.timelineState.paginationState.backward)
    }
    
    private func backpaginateIfNecessary(paginationStatus: PaginationStatus) {
        if paginationStatus == .idle, isTopVisible {
            activeTimelineViewModel.context.send(viewAction: .paginateBackwards)
        }
    }
}
