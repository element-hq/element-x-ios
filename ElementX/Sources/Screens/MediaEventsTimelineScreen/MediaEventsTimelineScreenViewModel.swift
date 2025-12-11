//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias MediaEventsTimelineScreenViewModelType = StateStoreViewModelV2<MediaEventsTimelineScreenViewState, MediaEventsTimelineScreenViewAction>

class MediaEventsTimelineScreenViewModel: MediaEventsTimelineScreenViewModelType, MediaEventsTimelineScreenViewModelProtocol {
    private let mediaTimelineViewModel: TimelineViewModelProtocol
    private let filesTimelineViewModel: TimelineViewModelProtocol
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    
    private var isOldestItemVisible = false
    
    private var activeTimelineViewModel: TimelineViewModelProtocol {
        switch state.bindings.screenMode {
        case .media:
            mediaTimelineViewModel
        case .files:
            filesTimelineViewModel
        }
    }
    
    private var mediaPreviewCancellable: AnyCancellable?
    
    private let actionsSubject: PassthroughSubject<MediaEventsTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MediaEventsTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(mediaTimelineViewModel: TimelineViewModelProtocol,
         filesTimelineViewModel: TimelineViewModelProtocol,
         initialScreenMode: MediaEventsTimelineScreenMode = .media,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol) {
        self.mediaTimelineViewModel = mediaTimelineViewModel
        self.filesTimelineViewModel = filesTimelineViewModel
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        
        let activeTimelineContext = switch initialScreenMode {
        case .media: mediaTimelineViewModel.context
        case .files: filesTimelineViewModel.context
        }
        
        super.init(initialViewState: .init(activeTimelineContext: activeTimelineContext, bindings: .init(screenMode: initialScreenMode)), mediaProvider: mediaProvider)
                
        mediaTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.bindings.screenMode == .media else {
                return
            }
            
            updateWithTimelineViewState(timelineViewState)
        }
        .store(in: &cancellables)
        
        mediaTimelineViewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .displayMediaPreview(let mediaPreviewViewModel):
                displayMediaPreview(mediaPreviewViewModel)
            case .displayMediaDetails(item: let item):
                displayMediaPreviewSheet(for: item)
            case .displayEmojiPicker, .displayReportContent, .displayCameraPicker, .displayMediaPicker,
                 .displayDocumentPicker, .displayLocationPicker, .displayPollForm, .displayMediaUploadPreviewScreen,
                 .displaySenderDetails, .displayMessageForwarding, .displayLocation, .displayResolveSendFailure,
                 .displayThread, .composer, .hasScrolled, .viewInRoomTimeline, .displayRoom:
                break
            }
        }
        .store(in: &cancellables)
        
        filesTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.bindings.screenMode == .files else {
                return
            }
            
            updateWithTimelineViewState(timelineViewState)
        }
        .store(in: &cancellables)
        
        filesTimelineViewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .displayMediaPreview(let mediaPreviewViewModel):
                displayMediaPreview(mediaPreviewViewModel)
            case .displayMediaDetails(item: let item):
                displayMediaPreviewSheet(for: item)
            case .displayEmojiPicker, .displayReportContent, .displayCameraPicker, .displayMediaPicker,
                 .displayDocumentPicker, .displayLocationPicker, .displayPollForm, .displayMediaUploadPreviewScreen,
                 .displaySenderDetails, .displayMessageForwarding, .displayLocation, .displayResolveSendFailure,
                 .displayThread, .composer, .hasScrolled, .viewInRoomTimeline, .displayRoom:
                break
            }
        }
        .store(in: &cancellables)
        
        updateWithTimelineViewState(activeTimelineViewModel.context.viewState)
    }
    
    // MARK: - Public
    
    override func process(viewAction: MediaEventsTimelineScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .changedScreenMode:
            switch state.bindings.screenMode {
            case .media: state.activeTimelineContext = mediaTimelineViewModel.context
            case .files: state.activeTimelineContext = filesTimelineViewModel.context
            }
            
            updateWithTimelineViewState(activeTimelineViewModel.context.viewState)
        case .oldestItemDidAppear:
            isOldestItemVisible = true
            backPaginateIfNecessary(paginationStatus: activeTimelineViewModel.context.viewState.timelineState.paginationState.backward)
        case .oldestItemDidDisappear:
            isOldestItemVisible = false
        case .tappedItem(let item):
            activeTimelineViewModel.context.send(viewAction: .mediaTapped(itemID: item.identifier))
        case .longPressedItem(let item):
            activeTimelineViewModel.context.send(viewAction: .displayTimelineItemMenu(itemID: item.identifier))
        }
    }
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewViewModel = nil
    }
    
    // MARK: - Private
    
    private func displayMediaPreviewSheet(for item: EventBasedMessageTimelineItemProtocol) {
        let sheetModel = TimelineMediaPreviewViewModel(initialItem: item,
                                                       timelineViewModel: activeTimelineViewModel,
                                                       mediaProvider: mediaProvider,
                                                       photoLibraryManager: PhotoLibraryManager(),
                                                       userIndicatorController: userIndicatorController,
                                                       appMediator: appMediator)
        sheetModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .displayMessageForwarding(let forwardingItem):
                displayMessageForwarding(forwardingItem: forwardingItem)
            case .viewInRoomTimeline(let itemID):
                actionsSubject.send(.viewInRoomTimeline(itemID))
            case .dismiss:
                state.bindings.mediaPreviewSheetViewModel = nil
            }
        }
        .store(in: &cancellables)
        
        // Triggers a download of the item so that can be shared/saved
        sheetModel.context.send(viewAction: .updateCurrentItem(sheetModel.state.currentItem))
        state.bindings.mediaPreviewSheetViewModel = sheetModel
    }
    
    private func updateWithTimelineViewState(_ timelineViewState: TimelineViewState) {
        var newGroups = [MediaEventsTimelineGroup]()
        var currentItems = [RoomTimelineItemViewState]()
        
        timelineViewState.timelineState.itemViewStates.filter { itemViewState in
            switch itemViewState.type {
            case .image, .video:
                state.bindings.screenMode == .media
            case .audio, .file, .voice:
                state.bindings.screenMode == .files
            case .separator:
                true
            default:
                false
            }
        }.reversed().forEach { item in
            if case .separator(let item) = item.type {
                let group = MediaEventsTimelineGroup(id: item.id.uniqueID.value,
                                                     title: titleForDate(item.timestamp),
                                                     items: currentItems)
                if !currentItems.isEmpty {
                    newGroups.append(group)
                    currentItems = []
                }
            } else {
                currentItems.append(item)
            }
        }
        
        if !currentItems.isEmpty {
            MXLog.warning("Found ungrouped timeline items, appending them at end.")
            let group = MediaEventsTimelineGroup(id: UUID().uuidString,
                                                 title: titleForDate(.now),
                                                 items: currentItems)
            newGroups.append(group)
        }

        state.groups = newGroups
        
        state.isBackPaginating = timelineViewState.timelineState.paginationState.backward == .paginating
        state.shouldShowEmptyState = newGroups.isEmpty && timelineViewState.timelineState.paginationState.backward == .timelineEndReached
        backPaginateIfNecessary(paginationStatus: timelineViewState.timelineState.paginationState.backward)
    }
    
    private func backPaginateIfNecessary(paginationStatus: PaginationStatus) {
        if paginationStatus == .idle, isOldestItemVisible {
            activeTimelineViewModel.context.send(viewAction: .paginateBackwards)
        }
    }
    
    private func displayMediaPreview(_ viewModel: TimelineMediaPreviewViewModel) {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .displayMessageForwarding(let forwardingItem):
                displayMessageForwarding(forwardingItem: forwardingItem)
            case .viewInRoomTimeline(let itemID):
                state.bindings.mediaPreviewViewModel = nil
                actionsSubject.send(.viewInRoomTimeline(itemID))
            case .dismiss:
                state.bindings.mediaPreviewViewModel = nil
            }
        }
        .store(in: &cancellables)
        
        state.bindings.mediaPreviewViewModel = viewModel
    }
    
    private func titleForDate(_ date: Date) -> String {
        if Calendar.current.isDate(date, equalTo: .now, toGranularity: .month) {
            L10n.commonDateThisMonth
        } else {
            date.formatted(.dateTime.month(.wide).year())
        }
    }
    
    private func displayMessageForwarding(forwardingItem: MessageForwardingItem) {
        state.bindings.mediaPreviewViewModel = nil
        state.bindings.mediaPreviewSheetViewModel = nil
        // We need a small delay because we need to wait for the presented sheet to be fully dismissed.
        DispatchQueue.main.asyncAfter(deadline: .now() + TimelineMediaPreviewViewModel.displayMessageForwardingDelay) {
            self.actionsSubject.send(.displayMessageForwarding(forwardingItem))
        }
    }
}
