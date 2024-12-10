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
    private let userIndicatorController: UserIndicatorControllerProtocol
    
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
         screenMode: MediaEventsTimelineScreenMode = .media,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.mediaTimelineViewModel = mediaTimelineViewModel
        self.filesTimelineViewModel = filesTimelineViewModel
        self.userIndicatorController = userIndicatorController
        
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
        case .tappedItem(let item):
            handleItemTapped(item)
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
    
    private func handleItemTapped(_ item: RoomTimelineItemViewState) {
        let item: EventBasedMessageTimelineItemProtocol? = switch item.type {
        case .audio(let audioItem): audioItem
        case .file(let fileItem): fileItem
        case .image(let imageItem): imageItem
        case .video(let videoItem): videoItem
        default: nil
        }
        
        guard let item, let mediaProvider = context.mediaProvider else {
            MXLog.error("Unexpected item type (or the media provider is missing).")
            return
        }
        
        let viewModel = TimelineMediaPreviewViewModel(previewItems: [item],
                                                      mediaProvider: mediaProvider,
                                                      userIndicatorController: userIndicatorController)
        state.bindings.mediaPreviewViewModel = viewModel
    }
}
