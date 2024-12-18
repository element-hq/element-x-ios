//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        let previewItems = timelineViewModel.context.viewState.timelineState.itemViewStates.compactMap(TimelineMediaPreviewItem.init)
        let initialItemIndex = previewItems.firstIndex { $0.id == context.item.id } ?? 0
        let currentItem = previewItems[initialItemIndex]
        
        super.init(initialViewState: TimelineMediaPreviewViewState(previewItems: previewItems,
                                                                   initialItemIndex: initialItemIndex,
                                                                   currentItem: currentItem,
                                                                   transitionNamespace: context.namespace),
                   mediaProvider: mediaProvider)
        
        rebuildCurrentItemActions()
        
        timelineViewModel.context.$viewState.map(\.canCurrentUserRedactSelf)
            .merge(with: timelineViewModel.context.$viewState.map(\.canCurrentUserRedactOthers))
            .sink { [weak self] _ in
                self?.rebuildCurrentItemActions()
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: TimelineMediaPreviewViewAction) {
        switch viewAction {
        case .updateCurrentItem(let item):
            Task { await updateCurrentItem(item) }
        case .saveCurrentItem:
            Task { await saveCurrentItem() }
        case .showCurrentItemDetails:
            state.bindings.mediaDetailsItem = state.currentItem
        case .menuAction(let action, let item):
            switch action {
            case .viewInRoomTimeline:
                actionsSubject.send(.viewInRoomTimeline(item.id))
            case .redact:
                state.bindings.redactConfirmationItem = item
            default:
                MXLog.error("Received unexpected action: \(action)")
            }
        case .redactConfirmation(let item):
            redactItem(item)
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    private func updateCurrentItem(_ previewItem: TimelineMediaPreviewItem) async {
        state.currentItem = previewItem
        currentItemIDHandler?(previewItem.id)
        rebuildCurrentItemActions()
        
        if previewItem.fileHandle == nil, let source = previewItem.mediaSource {
            showDownloadingIndicator(itemID: previewItem.id)
            defer { hideDownloadingIndicator(itemID: previewItem.id) }
            
            switch await mediaProvider.loadFileFromSource(source, filename: previewItem.filename) {
            case .success(let handle):
                previewItem.fileHandle = handle
                state.fileLoadedPublisher.send(previewItem.id)
            case .failure(let error):
                MXLog.error("Failed loading media: \(error)")
                showDownloadErrorIndicator()
            }
        }
    }
    
    private func rebuildCurrentItemActions() {
        let timelineContext = timelineViewModel.context
        let provider = TimelineItemMenuActionProvider(timelineItem: state.currentItem.timelineItem,
                                                      canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                                      canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                                      canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                                      pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                                      isDM: timelineContext.viewState.isEncryptedOneToOneRoom,
                                                      isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                                      isCreateMediaCaptionsEnabled: timelineContext.viewState.isCreateMediaCaptionsEnabled,
                                                      timelineKind: timelineContext.viewState.timelineKind,
                                                      emojiProvider: timelineContext.viewState.emojiProvider)
        state.currentItemActions = provider.makeActions()
    }
    
    private func saveCurrentItem() async {
        guard let fileURL = state.currentItem.fileHandle?.url else {
            MXLog.error("Unable to save an item without a URL, the button shouldn't be visible.")
            return
        }
        
        do {
            switch state.currentItem.timelineItem {
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
    
    private func redactItem(_ item: TimelineMediaPreviewItem) {
        timelineViewModel.context.send(viewAction: .handleTimelineItemMenuAction(itemID: item.id, action: .redact))
        state.bindings.redactConfirmationItem = nil
        state.bindings.mediaDetailsItem = nil
        actionsSubject.send(.dismiss)
        showRedactedIndicator()
    }
    
    // MARK: - Indicators
    
    private func showDownloadingIndicator(itemID: TimelineItemIdentifier) {
        let indicatorID = makeDownloadIndicatorID(itemID: itemID)
        userIndicatorController.submitIndicator(UserIndicator(id: indicatorID,
                                                              type: .toast(progress: .indeterminate),
                                                              title: L10n.commonDownloading,
                                                              persistent: true),
                                                delay: .seconds(0.1)) // Don't show the indicator when the SDK loads the file from the store.
    }
    
    private func hideDownloadingIndicator(itemID: TimelineItemIdentifier) {
        let indicatorID = makeDownloadIndicatorID(itemID: itemID)
        userIndicatorController.retractIndicatorWithId(indicatorID)
    }
    
    // FIXME: Add the strings and correct indicator types
    private func showDownloadErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: downloadErrorIndicatorID,
                                                              type: .modal,
                                                              title: L10n.errorUnknown,
                                                              iconName: "exclamationmark.circle.fill"))
    }
    
    private func showRedactedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: "File deleted",
                                                              iconName: "checkmark"))
    }
    
    private func showSavedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: "File saved",
                                                              iconName: "checkmark"))
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
    
    private var statusIndicatorID: String { "\(Self.self)-Status" }
    
    // Separate indicator IDs for downloads as these can be triggered in the background when swiping between items
    private var downloadErrorIndicatorID: String { "\(Self.self)-DownloadError" }
    private func makeDownloadIndicatorID(itemID: TimelineItemIdentifier) -> String {
        "\(Self.self)-Download-\(itemID.uniqueID.id)"
    }
}
