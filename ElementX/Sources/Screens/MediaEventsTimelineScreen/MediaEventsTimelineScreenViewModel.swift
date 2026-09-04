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
    private let appSettings: AppSettings
    
    private var isOldestItemVisible = false
    
    /// The gallery item that a listed item was built from, so that interactions can be forwarded
    /// using the gallery's identifier rather than the listed item's.
    private var galleryItemIDs = [TimelineItemIdentifier.UniqueID: GalleryItemID]()
    
    private var activeTimelineViewModel: TimelineViewModelProtocol {
        switch state.screenMode {
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
         initialScreenMode: MediaEventsTimelineScreenMode = .media,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings) {
        self.mediaTimelineViewModel = mediaTimelineViewModel
        self.filesTimelineViewModel = filesTimelineViewModel
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.appSettings = appSettings
        
        let activeTimelineContext = switch initialScreenMode {
        case .media: mediaTimelineViewModel.context
        case .files: filesTimelineViewModel.context
        }
        
        super.init(initialViewState: .init(screenMode: initialScreenMode,
                                           activeTimelineContext: activeTimelineContext,
                                           bindings: .init()),
                   mediaProvider: mediaProvider)
        
        mediaTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.screenMode == .media else {
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
                 .displayDocumentPicker, .displayLocationPicker, .displayLiveLocation, .displayNewPollForm, .displayEditPollForm, .displayMediaUploadPreviewScreen,
                 .displaySenderDetails, .displayMessageForwarding, .displayLocation, .displayResolveSendFailure,
                 .displayThread, .composer, .hasScrolled, .viewInRoomTimeline, .displayRoom, .presentCallScreen:
                break
            }
        }
        .store(in: &cancellables)
        
        filesTimelineViewModel.context.$viewState.sink { [weak self] timelineViewState in
            guard let self, state.screenMode == .files else {
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
                 .displayDocumentPicker, .displayLocationPicker, .displayLiveLocation, .displayNewPollForm, .displayEditPollForm, .displayMediaUploadPreviewScreen,
                 .displaySenderDetails, .displayMessageForwarding, .displayLocation, .displayResolveSendFailure,
                 .displayThread, .composer, .hasScrolled, .viewInRoomTimeline, .displayRoom, .presentCallScreen:
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
        case .changeScreenMode(let screenMode):
            changeScreenMode(to: screenMode)
        case .oldestItemDidAppear:
            isOldestItemVisible = true
            backPaginateIfNecessary(backPaginationState: activeTimelineViewModel.context.viewState.timelineState.paginationState.backward)
        case .oldestItemDidDisappear:
            isOldestItemVisible = false
        case .tappedItem(let item):
            if let galleryItemID = galleryItemIDs[item.id] {
                activeTimelineViewModel.context.send(viewAction: .galleryItemTapped(galleryItemID))
            } else {
                activeTimelineViewModel.context.send(viewAction: .mediaTapped(itemID: item.identifier))
            }
        case .longPressedItem(let item):
            // The menu acts on the gallery as a whole, as its actions can't apply to a single item.
            let itemID = galleryItemIDs[item.id]?.timelineItemID ?? item.identifier
            activeTimelineViewModel.context.send(viewAction: .displayTimelineItemMenu(itemID: itemID))
        }
    }
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewViewModel = nil
    }
    
    // MARK: - Private
    
    private func changeScreenMode(to screenMode: MediaEventsTimelineScreenMode) {
        guard screenMode != state.screenMode else { return }
        
        state.screenMode = screenMode
        
        switch screenMode {
        case .media: state.activeTimelineContext = mediaTimelineViewModel.context
        case .files: state.activeTimelineContext = filesTimelineViewModel.context
        }
        
        updateWithTimelineViewState(activeTimelineViewModel.context.viewState)
    }
    
    private func displayMediaPreviewSheet(for item: EventBasedMessageTimelineItemProtocol) {
        let sheetModel = TimelineMediaPreviewViewModel(initialItem: item,
                                                       timelineViewModel: activeTimelineViewModel,
                                                       mediaProvider: mediaProvider,
                                                       photoLibraryManager: PhotoLibraryManager(),
                                                       userIndicatorController: userIndicatorController,
                                                       appMediator: appMediator,
                                                       appSettings: appSettings)
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
        var newGalleryItemIDs = [TimelineItemIdentifier.UniqueID: GalleryItemID]()
        
        timelineViewState.timelineState.itemViewStates.flatMap { itemViewState -> [RoomTimelineItemViewState] in
            switch itemViewState.type {
            case .image, .video:
                return state.screenMode == .media ? [itemViewState] : []
            case .audio, .file, .voice:
                return state.screenMode == .files ? [itemViewState] : []
            case .separator:
                return [itemViewState]
            case .gallery(let galleryItem):
                let flattenedItems = galleryItem.itemsAsIndividualMessages(allowedTypes: timelineViewState.allowedGalleryItemTypes)
                for (mediaIndex, item) in flattenedItems {
                    newGalleryItemIDs[item.id.uniqueID] = .init(timelineItemID: galleryItem.id, mediaIndex: mediaIndex)
                }
                return flattenedItems.map { .init(item: $0.item, groupStyle: .single) }
            default:
                return []
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
        galleryItemIDs = newGalleryItemIDs
        
        state.isBackPaginating = timelineViewState.timelineState.paginationState.backward == .paginating
        state.shouldShowEmptyState = newGroups.isEmpty && timelineViewState.timelineState.paginationState.backward == .endReached
        backPaginateIfNecessary(backPaginationState: timelineViewState.timelineState.paginationState.backward)
    }
    
    private func backPaginateIfNecessary(backPaginationState: PaginationState) {
        if backPaginationState == .idle, isOldestItemVisible {
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

private extension GalleryRoomTimelineItem {
    /// Represents the gallery's attachments of the given types as though each had been sent as an
    /// individual message, so that the screen can list them alongside the room's other media. Each one
    /// keeps the gallery's event ID but is given its own unique ID so that they remain distinct.
    func itemsAsIndividualMessages(allowedTypes: [TimelineAllowedGalleryItemType]?) -> [(mediaIndex: Int, item: EventBasedMessageTimelineItemProtocol)] {
        guard let eventOrTransactionID = id.eventOrTransactionID else { return [] }
        
        return content.items(matching: allowedTypes).compactMap { mediaIndex, galleryItem in
            let itemID = TimelineItemIdentifier.event(uniqueID: .init("\(id.uniqueID.value)-\(mediaIndex)"),
                                                      eventOrTransactionID: eventOrTransactionID)
            
            let item: EventBasedMessageTimelineItemProtocol? = switch galleryItem {
            case .image(_, let content):
                ImageRoomTimelineItem(id: itemID, timestamp: timestamp, isOutgoing: isOutgoing, isEditable: isEditable,
                                      canBeRepliedTo: canBeRepliedTo, sender: sender, content: content, properties: properties)
            case .video(_, let content):
                VideoRoomTimelineItem(id: itemID, timestamp: timestamp, isOutgoing: isOutgoing, isEditable: isEditable,
                                      canBeRepliedTo: canBeRepliedTo, sender: sender, content: content, properties: properties)
            case .audio(_, let content):
                AudioRoomTimelineItem(id: itemID, timestamp: timestamp, isOutgoing: isOutgoing, isEditable: isEditable,
                                      canBeRepliedTo: canBeRepliedTo, sender: sender, content: content, properties: properties)
            case .file(_, let content):
                FileRoomTimelineItem(id: itemID, timestamp: timestamp, isOutgoing: isOutgoing, isEditable: isEditable,
                                     canBeRepliedTo: canBeRepliedTo, sender: sender, content: content, properties: properties)
            case .other:
                nil // Filtered out above, as there's nothing to show for it.
            }
            
            guard let item else { return nil }
            return (mediaIndex, item)
        }
    }
}
