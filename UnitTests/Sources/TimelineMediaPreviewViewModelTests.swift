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
    var timelineController: MockRoomTimelineController!
    
    func testLoadingItem() async {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
        
        // When the preview controller sets the current item.
        await viewModel.updateCurrentItem(context.viewState.previewItems[0])
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
    }
    
    func testViewInRoomTimeline() async throws {
        // Given a view model with a loaded item.
        await testLoadingItem()
        
        // When choosing to view the current item in the timeline.
        let currentItemID = context.viewState.currentItem.id
        let deferred = deferFulfillment(viewModel.actions) { $0 == .viewInRoomTimeline(currentItemID) }
        context.send(viewAction: .menuAction(.viewInRoomTimeline))
        
        // Then the action should be sent upwards to make this happen.
        try await deferred.fulfill()
    }
    
    func testRedactConfirmation() async throws {
        // Given a view model with a loaded item.
        await testLoadingItem()
        XCTAssertFalse(context.isPresentingRedactConfirmation)
        XCTAssertFalse(timelineController.redactCalled)
        
        // When choosing to redact the current item.
        context.send(viewAction: .menuAction(.redact))
        
        // Then the confirmation sheet should be presented.
        XCTAssertTrue(context.isPresentingRedactConfirmation)
        XCTAssertFalse(timelineController.redactCalled)
        
        // When confirming the redaction.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .redactConfirmation)
        
        // Then the item should be redacted and the view should be dismissed.
        try await deferred.fulfill()
        XCTAssertTrue(timelineController.redactCalled)
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
        
        timelineController = MockRoomTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = [item]
        
        mediaProvider = MediaProviderMock(configuration: .init())
        viewModel = TimelineMediaPreviewViewModel(initialItem: item,
                                                  timelineViewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                            timelineController: timelineController),
                                                  mediaProvider: mediaProvider,
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
}
