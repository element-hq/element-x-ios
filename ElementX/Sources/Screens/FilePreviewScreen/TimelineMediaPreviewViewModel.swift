//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

typealias TimelineMediaPreviewViewModelType = StateStoreViewModel<TimelineMediaPreviewViewState, TimelineMediaPreviewViewAction>

class TimelineMediaPreviewViewModel: TimelineMediaPreviewViewModelType {
    static let displayMessageForwardingDelay: TimeInterval = 1.0
    
    let instanceID = UUID()
    
    private let timelineViewModel: TimelineViewModelProtocol
    private let mediaProvider: MediaProviderProtocol
    private let photoLibraryManager: PhotoLibraryManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    
    private var contentScannerService: ContentScannerServiceProtocol? {
        timelineViewModel.context.contentScannerService
    }
    
    private let actionsSubject: PassthroughSubject<TimelineMediaPreviewViewModelAction, Never> = .init()
    var actions: AnyPublisher<TimelineMediaPreviewViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(initialItem: EventBasedMessageTimelineItemProtocol,
         timelineViewModel: TimelineViewModelProtocol,
         mediaProvider: MediaProviderProtocol,
         photoLibraryManager: PhotoLibraryManagerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol) {
        self.timelineViewModel = timelineViewModel
        self.mediaProvider = mediaProvider
        self.photoLibraryManager = photoLibraryManager
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        
        let timelineState = timelineViewModel.context.viewState.timelineState
        
        super.init(initialViewState: TimelineMediaPreviewViewState(dataSource: .init(itemViewStates: timelineState.itemViewStates,
                                                                                     initialItem: initialItem,
                                                                                     paginationState: timelineState.paginationState)),
                   mediaProvider: mediaProvider)
        
        rebuildCurrentItemActions()
        
        let canRedactSelfPublisher = timelineViewModel.context.$viewState.map(\.canCurrentUserRedactSelf)
        let canRedactOthersPublisher = timelineViewModel.context.$viewState.map(\.canCurrentUserRedactOthers)
        
        canRedactSelfPublisher.merge(with: canRedactOthersPublisher)
            .sink { [weak self] _ in
                self?.rebuildCurrentItemActions()
            }
            .store(in: &cancellables)
        
        timelineViewModel.context.$viewState.map(\.timelineState.itemViewStates)
            .removeDuplicates()
            .sink { [weak self] itemViewStates in
                self?.state.dataSource.updatePreviewItems(itemViewStates: itemViewStates)
            }
            .store(in: &cancellables)
        
        timelineViewModel.context.$viewState.map(\.timelineState.paginationState)
            .removeDuplicates()
            .sink { [weak self] paginationState in
                guard let self else { return }
                state.dataSource.paginationState = paginationState
                paginateIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: TimelineMediaPreviewViewAction) {
        switch viewAction {
        case .updateCurrentItem(let item):
            Task { await updateCurrentItem(item) }
        case .showItemDetails(let mediaItem):
            state.previewControllerDriver.send(.showItemDetails(mediaItem))
        case .menuAction(let action, let item):
            switch action {
            case .viewInRoomTimeline:
                state.previewControllerDriver.send(.dismissDetailsSheet)
                actionsSubject.send(.viewInRoomTimeline(item.timelineItem.id))
            case .downloadMedia:
                Task { await saveCurrentItem() }
            case .redact:
                state.bindings.redactConfirmationItem = item
            case .forward(let itemID):
                Task { await forwardItem(itemID: itemID) }
            default:
                MXLog.error("Received unexpected action: \(action)")
            }
        case .redactConfirmation(let item):
            redactItem(item)
        case .timelineEndReached:
            showTimelineEndIndicator()
        }
    }
    
    private func forwardItem(itemID: TimelineItemIdentifier) async {
        guard let forwardingItem = await timelineViewModel.makeForwardingItem(for: itemID) else { return }
        state.previewControllerDriver.send(.dismissDetailsSheet)
        actionsSubject.send(.displayMessageForwarding(forwardingItem))
    }
    
    private func updateCurrentItem(_ previewItem: TimelineMediaPreviewItem) async {
        if case let .media(item) = previewItem {
            item.downloadError = nil // Clear any existing error so that the download is retried.
        }
        setCurrentItem(previewItem)
        
        if case let .media(mediaItem) = previewItem {
            guard mediaItem.fileHandle == nil, let source = mediaItem.mediaSource else { return }
            
            guard await checkSourceIsSafeIfNeeded(for: mediaItem, source: source) else { return }
            
            switch await mediaProvider.loadFileFromSource(source, filename: mediaItem.filename) {
            case .success(let handle):
                mediaItem.fileHandle = handle
                state.previewControllerDriver.send(.itemLoaded(mediaItem.id))
            case .failure(let error):
                MXLog.error("Failed loading media: \(error)")
                context.objectWillChange.send() // Manually trigger the SwiftUI view update.
                mediaItem.downloadError = error
            }
        } else {
            paginateIfNeeded()
        }
    }
    
    /// Scans the media when a content scanner is configured, returning whether it's safe to be downloaded
    /// and previewed, reflecting the scan's progress and outcome in the current item. Both the media and
    /// its thumbnail are scanned as either being downloaded through the scanner can flag the media.
    private func checkSourceIsSafeIfNeeded(for mediaItem: TimelineMediaPreviewItem.Media, source: MediaSourceProxy) async -> Bool {
        guard let contentScannerService else { return true }
        
        let sources = [source, mediaItem.thumbnailMediaSource].compactMap { $0 }
        
        // Only reflect the scanning state when there's no cached verdict, so that
        // scanned items don't flash the scanning indicator when they're revisited.
        if contentScannerService.scanResultFromSources(sources) == nil {
            setCurrentItem(.contentScan(.init(media: mediaItem, state: .scanning)))
        }
        
        switch await contentScannerService.loadScanResultFromSources(sources) {
        case .success(true):
            finishScan(with: .media(mediaItem), for: mediaItem)
            return true
        case .success(false):
            finishScan(with: .contentScan(.init(media: mediaItem, state: .failure(.notSafe))), for: mediaItem)
            return false
        case .failure:
            finishScan(with: .contentScan(.init(media: mediaItem, state: .failure(.notFound))), for: mediaItem)
            return false
        }
    }
    
    /// Reflects the outcome of a scan in the current item, unless the user has already swiped on to another item.
    private func finishScan(with previewItem: TimelineMediaPreviewItem, for mediaItem: TimelineMediaPreviewItem.Media) {
        guard state.currentItem.mediaItem === mediaItem else { return }
        setCurrentItem(previewItem)
    }
    
    private func setCurrentItem(_ previewItem: TimelineMediaPreviewItem) {
        context.objectWillChange.send() // The data source is a reference type so the view needs a manual update.
        state.dataSource.updateCurrentItem(previewItem)
        rebuildCurrentItemActions()
    }
    
    private func paginateIfNeeded() {
        switch state.currentItem {
        case .loading(.paginatingBackwards):
            if state.dataSource.paginationState.backward == .idle {
                timelineViewModel.context.send(viewAction: .paginateBackwards)
            }
        case .loading(.paginatingForwards):
            if state.dataSource.paginationState.forward == .idle {
                timelineViewModel.context.send(viewAction: .paginateForwards)
            }
        default:
            break
        }
    }
    
    private func rebuildCurrentItemActions() {
        let timelineContext = timelineViewModel.context
        state.currentItemActions = state.currentItem.mediaItem.flatMap { mediaItem in
            TimelineItemMenuActionProvider(timelineItem: mediaItem.timelineItem,
                                           canCurrentUserSendMessage: timelineContext.viewState.canCurrentUserSendMessage,
                                           canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                           canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                           canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                           pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                           isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                           areThreadsEnabled: timelineContext.viewState.areThreadsEnabled,
                                           timelineKind: timelineContext.viewState.timelineKind,
                                           emojiProvider: timelineContext.viewState.emojiProvider)
                .makeActions()
        }
    }
    
    private func saveCurrentItem() async {
        guard case let .media(mediaItem) = state.currentItem, let fileURL = mediaItem.fileHandle?.url else {
            MXLog.error("Unable to save an item without a URL, the button shouldn't be visible.")
            return
        }
        
        // Dismiss the details sheet (nicer flow for images/video but _required_ in order to select a file directory).
        state.previewControllerDriver.send(.dismissDetailsSheet)
        
        do {
            switch mediaItem.timelineItem {
            case is AudioRoomTimelineItem, is FileRoomTimelineItem:
                state.previewControllerDriver.send(.exportFile(.init(url: fileURL)))
                return // Don't show the indicator.
            case is ImageRoomTimelineItem:
                try await photoLibraryManager.addResource(.photo, at: fileURL).get()
            case is VideoRoomTimelineItem:
                try await photoLibraryManager.addResource(.video, at: fileURL).get()
            default:
                break
            }
            
            showSavedIndicator()
        } catch PhotoLibraryManagerError.notAuthorized {
            MXLog.error("Not authorised to save item to photo library")
            state.previewControllerDriver.send(.authorizationRequired(appMediator: appMediator))
        } catch {
            MXLog.error("Failed saving item: \(error)")
            showErrorIndicator()
        }
    }
    
    private func redactItem(_ item: TimelineMediaPreviewItem.Media) {
        timelineViewModel.context.send(viewAction: .handleTimelineItemMenuAction(itemID: item.timelineItem.id, action: .redact(isMedia: true)))
        state.bindings.redactConfirmationItem = nil
        state.previewControllerDriver.send(.dismissDetailsSheet)
        actionsSubject.send(.dismiss)
        showRedactedIndicator()
    }
    
    // MARK: - Indicators
    
    private func showRedactedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonFileDeleted,
                                                              icon: \.check))
    }
    
    private func showSavedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonFileSaved,
                                                              icon: \.check))
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              icon: \.close))
    }
    
    private func showTimelineEndIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.screenMediaDetailsNoMoreMediaToShow))
    }
    
    private var statusIndicatorID: String {
        "\(Self.self)-Status"
    }
}
