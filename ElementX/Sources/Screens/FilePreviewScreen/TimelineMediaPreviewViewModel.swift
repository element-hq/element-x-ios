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
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<TimelineMediaPreviewViewModelAction, Never> = .init()
    var actions: AnyPublisher<TimelineMediaPreviewViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(initialItem: EventBasedMessageTimelineItemProtocol,
         timelineViewModel: TimelineViewModelProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.timelineViewModel = timelineViewModel
        self.mediaProvider = mediaProvider
        
        // We might not want to inject this, instead creating a new instance with a custom position and colour scheme 🤔
        self.userIndicatorController = userIndicatorController
        
        let currentItem = TimelineMediaPreviewItem(timelineItem: initialItem)
        
        super.init(initialViewState: TimelineMediaPreviewViewState(previewItems: [currentItem],
                                                                   currentItem: currentItem),
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
        case .menuAction(let action):
            switch action {
            case .viewInRoomTimeline:
                actionsSubject.send(.viewInTimeline)
            case .redact:
                state.bindings.isPresentingRedactConfirmation = true
            default:
                MXLog.error("Received unexpected action: \(action)")
            }
        case .redactConfirmation:
            break // Do it here??
        }
    }
    
    func updateCurrentItem(_ previewItem: TimelineMediaPreviewItem) async {
        state.currentItem = previewItem
        rebuildCurrentItemActions()
        
        if previewItem.fileHandle == nil, let source = previewItem.mediaSource {
            showDownloadingIndicator(itemID: previewItem.id)
            defer { hideDownloadingIndicator(itemID: previewItem.id) }
            
            switch await mediaProvider.loadFileFromSource(source) {
            case .success(let handle):
                previewItem.fileHandle = handle
                actionsSubject.send(.loadedMediaFile)
            case .failure(let error):
                MXLog.error("Failed loading media: \(error)")
                showDownloadErrorIndicator()
            }
        }
    }
    
    func rebuildCurrentItemActions() {
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
    
    private func showDownloadErrorIndicator() {
        // FIXME: Add the correct string and indicator type??
        userIndicatorController.submitIndicator(UserIndicator(id: downloadErrorIndicatorID,
                                                              type: .modal,
                                                              title: L10n.errorUnknown,
                                                              iconName: "exclamationmark.circle.fill"))
    }
    
    private var downloadErrorIndicatorID: String { "\(Self.self)-DownloadError" }
    private func makeDownloadIndicatorID(itemID: TimelineItemIdentifier) -> String {
        "\(Self.self)-Download-\(itemID.uniqueID.id)"
    }
}
