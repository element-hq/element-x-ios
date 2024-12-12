//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX

import Combine
import MatrixRustSDK
import SwiftUI
import XCTest

@MainActor
class TimelineMediaPreviewViewModelTests: XCTestCase {
    var viewModel: TimelineMediaPreviewViewModel!
    var context: TimelineMediaPreviewViewModel.Context { viewModel.context }
    var mediaProvider: MediaProviderMock!
    var timelineController: MockRoomTimelineController!
    
    func testLoadingItem() async throws {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
        
        // When the preview controller sets the current item.
        let deferred = deferFulfillment(viewModel.state.fileLoadedPublisher) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.previewItems[0]))
        try await deferred.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
    }
    
    func testViewInRoomTimeline() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When choosing to view the current item in the timeline.
        let item = context.viewState.currentItem
        let deferred = deferFulfillment(viewModel.actions) { $0 == .viewInRoomTimeline(item.id) }
        context.send(viewAction: .menuAction(.viewInRoomTimeline, item: item))
        
        // Then the action should be sent upwards to make this happen.
        try await deferred.fulfill()
    }
    
    func testRedactConfirmation() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        XCTAssertNil(context.redactConfirmationItem)
        XCTAssertFalse(timelineController.redactCalled)
        
        // When choosing to show the item details.
        context.send(viewAction: .showCurrentItemDetails)
        
        // Then the details sheet should be presented.
        guard let item = context.mediaDetailsItem else {
            XCTFail("The default of the current item should be presented")
            return
        }
        XCTAssertEqual(context.mediaDetailsItem, context.viewState.currentItem)
        
        // When choosing to redact the item.
        context.send(viewAction: .menuAction(.redact, item: item))
        
        // Then the confirmation sheet should be presented.
        XCTAssertEqual(context.redactConfirmationItem, item)
        XCTAssertFalse(timelineController.redactCalled)
        
        // When confirming the redaction.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .redactConfirmation(item: item))
        
        // Then the item should be redacted and the view should be dismissed.
        try await deferred.fulfill()
        XCTAssertTrue(timelineController.redactCalled)
    }
    
    func testDismiss() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When requesting to dismiss the view.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .dismiss)
        
        // Then the action should be sent upwards to make this happen.
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    @Namespace private var testNamespace
    
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
        viewModel = TimelineMediaPreviewViewModel(context: .init(item: item,
                                                                 viewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                                   timelineController: timelineController),
                                                                 namespace: testNamespace),
                                                  mediaProvider: mediaProvider,
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
}
