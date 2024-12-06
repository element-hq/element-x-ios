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
    private let mediaTimelineViewModel: TimelineViewModelProtocol
    private let filesTimelineViewModel: TimelineViewModelProtocol
    
    private var isOldestItemVisible = false
    
    private var activeTimelineViewModel: TimelineViewModelProtocol {
        switch state.bindings.screenMode {
        case .media:
            mediaTimelineViewModel
        case .files:
            filesTimelineViewModel
        }
    }
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(mediaTimelineViewModel: TimelineViewModelProtocol,
         filesTimelineViewModel: TimelineViewModelProtocol,
         mediaProvider: MediaProviderProtocol,
         screenMode: MediaEventsTimelineScreenMode = .media) {
        self.mediaTimelineViewModel = mediaTimelineViewModel
        self.filesTimelineViewModel = filesTimelineViewModel
        
        super.init(initialViewState: .init(bindings: .init(screenMode: screenMode)), mediaProvider: mediaProvider)
        
        mediaTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.bindings.screenMode == .media else {
                return
            }
            
            updateWithTimelineViewState(timelineViewState)
        }
        .store(in: &cancellables)
        
        filesTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.bindings.screenMode == .files else {
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
        case .oldestItemDidAppear:
            isOldestItemVisible = true
            backPaginateIfNecessary(paginationStatus: activeTimelineViewModel.context.viewState.timelineState.paginationState.backward)
        case .oldestItemDidDisappear:
            isOldestItemVisible = false
        }
    }
    
    // MARK: - Private
    
    private func updateWithTimelineViewState(_ timelineViewState: TimelineViewState) {
        state.items = timelineViewState.timelineState.itemViewStates.filter { itemViewState in
            switch itemViewState.type {
            case .image, .video:
                state.bindings.screenMode == .media
            case .audio, .file:
                state.bindings.screenMode == .files
            default:
                false
            }
        }.reversed()
        
        state.isBackPaginating = (timelineViewState.timelineState.paginationState.backward == .paginating)
        backPaginateIfNecessary(paginationStatus: timelineViewState.timelineState.paginationState.backward)
    }
    
    private func backPaginateIfNecessary(paginationStatus: PaginationStatus) {
        if paginationStatus == .idle, isOldestItemVisible {
            activeTimelineViewModel.context.send(viewAction: .paginateBackwards)
        }
    }
}
