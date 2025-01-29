//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

typealias TimelineMediaPreviewViewModelType = StateStoreViewModel<TimelineMediaPreviewViewState, TimelineMediaPreviewViewAction>

class TimelineMediaPreviewViewModel: TimelineMediaPreviewViewModelType {
    private let timelineViewModel: TimelineViewModelProtocol
    private let currentItemIDHandler: ((TimelineItemIdentifier?) -> Void)?
    private let mediaProvider: MediaProviderProtocol
    private let photoLibraryManager: PhotoLibraryManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<TimelineMediaPreviewViewModelAction, Never> = .init()
    var actions: AnyPublisher<TimelineMediaPreviewViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(context: TimelineMediaPreviewContext,
         mediaProvider: MediaProviderProtocol,
         photoLibraryManager: PhotoLibraryManagerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol) {
        timelineViewModel = context.viewModel
        currentItemIDHandler = context.itemIDHandler
        self.mediaProvider = mediaProvider
        self.photoLibraryManager = photoLibraryManager
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        
        let timelineState = timelineViewModel.context.viewState.timelineState
        
        super.init(initialViewState: TimelineMediaPreviewViewState(dataSource: .init(itemViewStates: timelineState.itemViewStates,
                                                                                     initialItem: context.item,
                                                                                     paginationState: timelineState.paginationState),
                                                                   transitionNamespace: context.namespace),
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
            .weakAssign(to: \.state.dataSource.paginationState, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: TimelineMediaPreviewViewAction) {
        switch viewAction {
        case .updateCurrentItem(let item):
            Task { await updateCurrentItem(item) }
        case .showItemDetails(let mediaItem):
            state.bindings.mediaDetailsItem = mediaItem
        case .menuAction(let action, let item):
            switch action {
            case .viewInRoomTimeline:
                actionsSubject.send(.viewInRoomTimeline(item.id))
            case .save:
                Task { await saveCurrentItem() }
            case .redact:
                state.bindings.redactConfirmationItem = item
            default:
                MXLog.error("Received unexpected action: \(action)")
            }
        case .redactConfirmation(let item):
            redactItem(item)
        case .timelineEndReached:
            showTimelineEndIndicator()
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    private func updateCurrentItem(_ previewItem: TimelineMediaPreviewItem) async {
        if case let .media(item) = previewItem {
            item.downloadError = nil // Clear any existing error.
        }
        state.dataSource.updateCurrentItem(previewItem)
        rebuildCurrentItemActions()
        
        if case let .media(mediaItem) = previewItem {
            currentItemIDHandler?(mediaItem.id)
            
            if mediaItem.fileHandle == nil, let source = mediaItem.mediaSource {
                switch await mediaProvider.loadFileFromSource(source, filename: mediaItem.filename) {
                case .success(let handle):
                    mediaItem.fileHandle = handle
                    state.fileLoadedPublisher.send(mediaItem.id)
                case .failure(let error):
                    MXLog.error("Failed loading media: \(error)")
                    context.objectWillChange.send() // Manually trigger the SwiftUI view update.
                    mediaItem.downloadError = error
                }
            }
        }
    }
    
    private func rebuildCurrentItemActions() {
        let timelineContext = timelineViewModel.context
        state.currentItemActions = switch state.currentItem {
        case .media(let mediaItem):
            TimelineItemMenuActionProvider(timelineItem: mediaItem.timelineItem,
                                           canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                           canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                           canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                           pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                           isDM: timelineContext.viewState.isEncryptedOneToOneRoom,
                                           isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                           timelineKind: timelineContext.viewState.timelineKind,
                                           emojiProvider: timelineContext.viewState.emojiProvider)
                .makeActions()
        case .loading:
            nil
        }
    }
    
    private func saveCurrentItem() async {
        guard case let .media(mediaItem) = state.currentItem, let fileURL = mediaItem.fileHandle?.url else {
            MXLog.error("Unable to save an item without a URL, the button shouldn't be visible.")
            return
        }
        
        // Dismiss the details sheet (nicer flow for images/video but _required_ in order to select a file directory).
        state.bindings.mediaDetailsItem = nil
        
        do {
            switch mediaItem.timelineItem {
            case is AudioRoomTimelineItem, is FileRoomTimelineItem:
                state.bindings.fileToExport = .init(url: fileURL)
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
            state.bindings.alertInfo = .init(id: .authorizationRequired,
                                             title: L10n.dialogPermissionPhotoLibraryTitleIos(InfoPlistReader.main.bundleDisplayName),
                                             primaryButton: .init(title: L10n.commonSettings) { self.appMediator.openAppSettings() },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        } catch {
            MXLog.error("Failed saving item: \(error)")
            showErrorIndicator()
        }
    }
    
    private func redactItem(_ item: TimelineMediaPreviewItem.Media) {
        timelineViewModel.context.send(viewAction: .handleTimelineItemMenuAction(itemID: item.id, action: .redact))
        state.bindings.redactConfirmationItem = nil
        state.bindings.mediaDetailsItem = nil
        actionsSubject.send(.dismiss)
        showRedactedIndicator()
    }
    
    // MARK: - Indicators
    
    private func showRedactedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonFileDeleted,
                                                              iconName: "checkmark"))
    }
    
    private func showSavedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonFileSaved,
                                                              iconName: "checkmark"))
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
    
    private func showTimelineEndIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.screenMediaDetailsNoMoreMediaToShow))
    }
    
    private var statusIndicatorID: String { "\(Self.self)-Status" }
}
