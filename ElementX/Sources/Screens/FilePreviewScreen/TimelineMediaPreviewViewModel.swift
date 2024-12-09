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
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<TimelineMediaPreviewViewModelAction, Never> = .init()
    var actions: AnyPublisher<TimelineMediaPreviewViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(previewItems: [EventBasedMessageTimelineItemProtocol], mediaProvider: MediaProviderProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        self.mediaProvider = mediaProvider
        
        // We might not want to inject this, instead creating a new instance with a custom position and colour scheme 🤔
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: TimelineMediaPreviewViewState(previewItems: previewItems.map(TimelineMediaPreviewItem.init)), mediaProvider: mediaProvider)
    }
    
    override func process(viewAction: TimelineMediaPreviewViewAction) {
        switch viewAction {
        case .viewInTimeline:
            actionsSubject.send(.viewInTimeline)
        case .redact:
            break // Do it here??
        }
    }
    
    func updateCurrentItem(_ previewItem: TimelineMediaPreviewItem) async {
        state.currentItem = previewItem
        
        if previewItem.fileHandle == nil, let source = previewItem.mediaSource {
            showDownloadingIndicator(itemID: previewItem.id)
            defer { hideDownloadingIndicator(itemID: previewItem.id) }
            
            switch await mediaProvider.loadFileFromSource(source) {
            case .success(let handle):
                previewItem.fileHandle = handle
                actionsSubject.send(.loadedMediaFile)
            case .failure(let error):
                MXLog.error("Failed loading media: \(error)")
                #warning("Show the error!")
            }
        }
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
    
    private func makeDownloadIndicatorID(itemID: TimelineItemIdentifier) -> String {
        "\(TimelineMediaPreviewViewModel.self)-Download-\(itemID.uniqueID.id)"
    }
}
