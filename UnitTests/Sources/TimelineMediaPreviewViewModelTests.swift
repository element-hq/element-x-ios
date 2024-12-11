//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX

import Combine
import MatrixRustSDK
import XCTest

@MainActor
class TimelineMediaPreviewViewModelTests: XCTestCase {
    var viewModel: TimelineMediaPreviewViewModel!
    var context: TimelineMediaPreviewViewModel.Context { viewModel.context }
    var mediaProvider: MediaProviderMock!
    
    func testLoadingItem() async throws {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        
        // When the preview controller sets the current item.
        await viewModel.updateCurrentItem(context.viewState.previewItems[0])
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
    }
    
    // MARK: - Helpers
    
    private func setupViewModel() {
        let item = ImageRoomTimelineItem(id: .randomEvent,
                                         timestamp: .mock,
                                         isOutgoing: false,
                                         isEditable: false,
                                         canBeRepliedTo: true,
                                         isThreaded: false,
                                         sender: .init(id: "", displayName: "Sally Sanderson"),
                                         content: .init(filename: "Amazing image.jpeg",
                                                        caption: "A caption goes right here.",
                                                        imageInfo: .mockImage,
                                                        thumbnailInfo: .mockThumbnail))
        
        mediaProvider = MediaProviderMock(configuration: .init())
        viewModel = TimelineMediaPreviewViewModel(initialItem: item,
                                                  isFromRoomScreen: false,
                                                  timelineViewModel: TimelineViewModel.mock,
                                                  mediaProvider: mediaProvider,
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
}
