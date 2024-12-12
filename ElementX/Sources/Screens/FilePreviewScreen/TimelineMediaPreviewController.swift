//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import QuickLook
import SwiftUI

class TimelineMediaPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    private let viewModelContext: TimelineMediaPreviewViewModel.Context
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(viewModelContext: TimelineMediaPreviewViewModel.Context) {
        #warning("Use the representable coordinator here once this view is simpler")
        self.viewModelContext = viewModelContext
        
        super.init(nibName: nil, bundle: nil)
        
        // Observation of currentPreviewItem doesn't work, so use the index instead.
        publisher(for: \.currentPreviewItemIndex)
            .sink { [weak self] _ in
                guard let self, let currentPreviewItem = currentPreviewItem as? TimelineMediaPreviewItem else { return }
                self.viewModelContext.send(viewAction: .updateCurrentItem(currentPreviewItem))
            }
            .store(in: &cancellables)
        
        viewModelContext.viewState.fileLoadedPublisher
            .sink { [weak self] itemID in
                guard let self, (currentPreviewItem as? TimelineMediaPreviewItem)?.id == itemID else { return }
                refreshCurrentPreviewItem()
            }
            .store(in: &cancellables)
        
        dataSource = self
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        viewModelContext.viewState.previewItems.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        viewModelContext.viewState.previewItems[index]
    }
}
