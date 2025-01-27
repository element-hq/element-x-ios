//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX

import Combine
import MatrixRustSDK
import QuickLook
import SwiftUI
import XCTest

@MainActor
class TimelineMediaPreviewViewModelTests: XCTestCase {
    var viewModel: TimelineMediaPreviewViewModel!
    var context: TimelineMediaPreviewViewModel.Context { viewModel.context }
    var mediaProvider: MediaProviderMock!
    var photoLibraryManager: PhotoLibraryManagerMock!
    var timelineController: MockRoomTimelineController!
    
    func testLoadingItem() async throws {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.dataSource.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
        
        // When the preview controller sets the current item.
        try await loadInitialItem()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.dataSource.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
    }
    
    func testLoadingItemFailure() async throws {
        // Given a fresh view model.
        setupViewModel()
        guard let currentItem = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(currentItem, context.viewState.dataSource.previewItems[0])
        XCTAssertNil(currentItem.downloadError)
        
        // When the preview controller sets an item that fails to load.
        mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
        let failure = deferFailure(viewModel.state.fileLoadedPublisher, timeout: 1) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.dataSource.previewItems[0]))
        try await failure.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(currentItem, context.viewState.dataSource.previewItems[0])
        XCTAssertNotNil(currentItem.downloadError)
    }
    
    func testSwipingBetweenItems() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When swiping to another item.
        let deferred = deferFulfillment(viewModel.state.fileLoadedPublisher) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.dataSource.previewItems[1]))
        try await deferred.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 2)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.dataSource.previewItems[1])
        
        // When swiping back to the first item.
        let failure = deferFailure(viewModel.state.fileLoadedPublisher, timeout: 1) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.dataSource.previewItems[0]))
        try await failure.fulfill()
        
        // Then the view model should not need to load the item, but should still update its view state.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 2)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.dataSource.previewItems[0])
    }
    
    func testLoadingMoreItem() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When swiping to a "loading more" item.
        let deferred = deferFailure(viewModel.state.fileLoadedPublisher, timeout: 1) { _ in true }
        context.send(viewAction: .updateCurrentItem(nil))
        try await deferred.fulfill()
        
        // Then there should no longer be a media preview and no attempt should be made to load one.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 1)
        XCTAssertNil(context.viewState.currentItem)
    }
    
    func testPagination() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        XCTAssertEqual(context.viewState.dataSource.previewItems.count, 3)
        
        // When more items are added via a back pagination.
        let deferred = deferFulfillment(context.viewState.dataSource.previewItemsPaginationPublisher) { _ in true }
        timelineController.backPaginationResponses.append(makeItems())
        _ = await timelineController.paginateBackwards(requestSize: 20)
        try await deferred.fulfill()
        
        // And the preview controller attempts to update the current item (now at a new index in the array but it hasn't changed in the data source).
        mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
        let failure = deferFailure(viewModel.state.fileLoadedPublisher, timeout: 1) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.dataSource.previewItems[3]))
        try await failure.fulfill()
        
        // Then the current item shouldn't need to be reloaded.
        XCTAssertEqual(context.viewState.dataSource.previewItems.count, 6)
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 1)
    }
    
    func testViewInRoomTimeline() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When choosing to view the current item in the timeline.
        guard let item = context.viewState.currentItem else {
            XCTFail("There should be a current item.")
            return
        }
        
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
    
    func testSaveImage() async throws {
        // Given a view model with a loaded image.
        try await testLoadingItem()
        guard let currentItem = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(currentItem.contentType, "JPEG image")
        
        // When choosing to save the image.
        context.send(viewAction: .menuAction(.save, item: currentItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the image should be saved as a photo to the user's photo library.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.type, .photo)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.url, currentItem.fileHandle?.url)
    }
    
    func testSaveImageWithoutAuthorization() async throws {
        // Given a view model with a loaded image where the user has denied access to the photo library.
        setupViewModel(photoLibraryAuthorizationDenied: true)
        try await loadInitialItem()
        guard let currentItem = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(currentItem.contentType, "JPEG image")
        
        // When choosing to save the image.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .menuAction(.save, item: currentItem))
        try await deferred.fulfill()
        
        // Then the user should be prompted to allow access.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(context.alertInfo?.id, .authorizationRequired)
    }
    
    func testSaveVideo() async throws {
        // Given a view model with a loaded video.
        setupViewModel(initialItemIndex: 1)
        try await loadInitialItem()
        guard let currentItem = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(currentItem.contentType, "MPEG-4 movie")
        
        // When choosing to save the video.
        context.send(viewAction: .menuAction(.save, item: currentItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the video should be saved as a video in the user's photo library.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.type, .video)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.url, currentItem.fileHandle?.url)
    }
    
    func testSaveFile() async throws {
        // Given a view model with a loaded file.
        setupViewModel(initialItemIndex: 2)
        try await loadInitialItem()
        guard let currentItem = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(currentItem.contentType, "PDF document")
        
        // When choosing to save the file.
        context.send(viewAction: .menuAction(.save, item: currentItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the binding should be set for the user to export the file to their specified location.
        XCTAssertFalse(photoLibraryManager.addResourceAtCalled)
        XCTAssertNotNil(context.fileToExport)
        XCTAssertEqual(context.fileToExport?.url, currentItem.fileHandle?.url)
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
    
    private func loadInitialItem() async throws {
        let deferred = deferFulfillment(viewModel.state.fileLoadedPublisher) { _ in true }
        let initialItem = context.viewState.dataSource.previewController(QLPreviewController(),
                                                                         previewItemAt: context.viewState.dataSource.initialItemIndex)
        guard let initialPreviewItem = initialItem as? TimelineMediaPreviewItem else {
            XCTFail("1234")
            return
        }
        context.send(viewAction: .updateCurrentItem(initialPreviewItem))
        try await deferred.fulfill()
    }
    
    @Namespace private var testNamespace
    
    private func setupViewModel(initialItemIndex: Int = 0, photoLibraryAuthorizationDenied: Bool = false) {
        let initialItems = makeItems()
        timelineController = MockRoomTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = initialItems
        
        mediaProvider = MediaProviderMock(configuration: .init())
        photoLibraryManager = PhotoLibraryManagerMock(.init(authorizationDenied: photoLibraryAuthorizationDenied))
        
        viewModel = TimelineMediaPreviewViewModel(context: .init(item: initialItems[initialItemIndex],
                                                                 viewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                                   timelineController: timelineController),
                                                                 namespace: testNamespace),
                                                  mediaProvider: mediaProvider,
                                                  photoLibraryManager: photoLibraryManager,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appMediator: AppMediatorMock())
    }
    
    private func makeItems() -> [EventBasedMessageTimelineItemProtocol] {
        [
            ImageRoomTimelineItem(id: .randomEvent,
                                  timestamp: .mock,
                                  isOutgoing: false,
                                  isEditable: false,
                                  canBeRepliedTo: true,
                                  isThreaded: false,
                                  sender: .init(id: "", displayName: "Sally Sanderson"),
                                  content: .init(filename: "Amazing image.jpeg",
                                                 caption: "A caption goes right here.",
                                                 imageInfo: .mockImage,
                                                 thumbnailInfo: .mockThumbnail,
                                                 contentType: .jpeg)),
            VideoRoomTimelineItem(id: .randomEvent,
                                  timestamp: .mock,
                                  isOutgoing: false,
                                  isEditable: false,
                                  canBeRepliedTo: true,
                                  isThreaded: false,
                                  sender: .init(id: ""),
                                  content: .init(filename: "Super video.mp4",
                                                 videoInfo: .mockVideo,
                                                 thumbnailInfo: .mockThumbnail,
                                                 contentType: .mpeg4Movie)),
            FileRoomTimelineItem(id: .randomEvent,
                                 timestamp: .mock,
                                 isOutgoing: false,
                                 isEditable: false,
                                 canBeRepliedTo: true,
                                 isThreaded: false,
                                 sender: .init(id: ""),
                                 content: .init(filename: "Important file.pdf",
                                                source: try? .init(url: .mockMXCFile, mimeType: "document/pdf"),
                                                fileSize: 2453,
                                                thumbnailSource: nil,
                                                contentType: .pdf))
        ]
    }
}
