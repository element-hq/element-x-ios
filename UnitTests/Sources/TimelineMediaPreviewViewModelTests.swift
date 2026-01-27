//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import QuickLook
import SwiftUI
import XCTest

@MainActor
class TimelineMediaPreviewViewModelTests: XCTestCase {
    var viewModel: TimelineMediaPreviewViewModel!
    var context: TimelineMediaPreviewViewModel.Context {
        viewModel.context
    }

    var mediaProvider: MediaProviderMock!
    var photoLibraryManager: PhotoLibraryManagerMock!
    var timelineController: MockTimelineController!
    
    func testLoadingItem() async throws {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, .media(context.viewState.dataSource.previewItems[0]))
        XCTAssertNotNil(context.viewState.currentItemActions)
        
        // When the preview controller sets the current item.
        try await loadInitialItem()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, .media(context.viewState.dataSource.previewItems[0]))
        XCTAssertNotNil(context.viewState.currentItemActions)
    }
    
    func testLoadingItemFailure() async throws {
        // Given a fresh view model.
        setupViewModel()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(mediaItem, context.viewState.dataSource.previewItems[0])
        XCTAssertNil(mediaItem.downloadError)
        
        // When the preview controller sets an item that fails to load.
        mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: 1) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[0])))
        try await failure.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(mediaItem, context.viewState.dataSource.previewItems[0])
        XCTAssertNotNil(mediaItem.downloadError)
    }
    
    func testSwipingBetweenItems() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When swiping to another item.
        let deferred = deferFulfillment(viewModel.state.previewControllerDriver) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[1])))
        try await deferred.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 2)
        XCTAssertEqual(context.viewState.currentItem, .media(context.viewState.dataSource.previewItems[1]))
        
        // When swiping back to the first item.
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: 1) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[0])))
        try await failure.fulfill()
        
        // Then the view model should not need to load the item, but should still update its view state.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 2)
        XCTAssertEqual(context.viewState.currentItem, .media(context.viewState.dataSource.previewItems[0]))
    }
    
    func testLoadingMoreItems() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        XCTAssertEqual(timelineController.paginateBackwardsCallCount, 0)
        
        // When swiping to a "loading more" item and there are more media items to load.
        timelineController.paginationState = .init(backward: .idle, forward: .endReached)
        timelineController.backPaginationResponses.append(RoomTimelineItemFixtures.mediaChunk)
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: 1) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.loading(.paginatingBackwards)))
        try await failure.fulfill()
        
        // Then there should no longer be a media preview and instead of loading any media, a pagination request should be made.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 1)
        XCTAssertEqual(context.viewState.currentItem, .loading(.paginatingBackwards)) // Note: This item only changes when the preview controller handles the new items.
        XCTAssertEqual(timelineController.paginateBackwardsCallCount, 1)
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
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: 1) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[3])))
        try await failure.fulfill()
        
        // Then the current item shouldn't need to be reloaded.
        XCTAssertEqual(context.viewState.dataSource.previewItems.count, 6)
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 1)
    }
    
    func testViewInRoomTimeline() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When choosing to view the current item in the timeline.
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item.")
            return
        }
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .viewInRoomTimeline(mediaItem.timelineItem.id) }
        context.send(viewAction: .menuAction(.viewInRoomTimeline, item: mediaItem))
        
        // Then the action should be sent upwards to make this happen.
        try await deferred.fulfill()
    }
    
    func testRedactConfirmation() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        XCTAssertNil(context.redactConfirmationItem)
        XCTAssertFalse(timelineController.redactCalled)
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item.")
            return
        }
        
        // When choosing to show the item details.
        let deferredDriver = deferFulfillment(context.viewState.previewControllerDriver) { $0.isShowItemDetails }
        context.send(viewAction: .showItemDetails(mediaItem))
        
        // Then the details sheet should be presented.
        let action = try await deferredDriver.fulfill()
        guard case let .showItemDetails(mediaDetailsItem) = action else {
            XCTFail("The action should include the media item.")
            return
        }
        XCTAssertEqual(.media(mediaDetailsItem), context.viewState.currentItem)
        
        // When choosing to redact the item.
        context.send(viewAction: .menuAction(.redact, item: mediaItem))
        
        // Then the confirmation sheet should be presented.
        XCTAssertEqual(context.redactConfirmationItem, mediaItem)
        XCTAssertFalse(timelineController.redactCalled)
        
        // When confirming the redaction.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .redactConfirmation(item: mediaItem))
        
        // Then the item should be redacted and the view should be dismissed.
        try await deferred.fulfill()
        XCTAssertTrue(timelineController.redactCalled)
    }
    
    func testSaveImage() async throws {
        // Given a view model with a loaded image.
        try await testLoadingItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(mediaItem.contentType, "JPEG image")
        
        // When choosing to save the image.
        context.send(viewAction: .menuAction(.save, item: mediaItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the image should be saved as a photo to the user's photo library.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.type, .photo)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.url, mediaItem.fileHandle?.url)
    }
    
    func testSaveImageWithoutAuthorization() async throws {
        // Given a view model with a loaded image where the user has denied access to the photo library.
        setupViewModel(photoLibraryAuthorizationDenied: true)
        try await loadInitialItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(mediaItem.contentType, "JPEG image")
        
        // When choosing to save the image.
        let deferred = deferFulfillment(context.viewState.previewControllerDriver) { $0.isAuthorizationRequired }
        context.send(viewAction: .menuAction(.save, item: mediaItem))
        
        // Then the user should be prompted to allow access.
        try await deferred.fulfill()
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
    }
    
    func testSaveVideo() async throws {
        // Given a view model with a loaded video.
        setupViewModel(initialItemIndex: 1)
        try await loadInitialItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(mediaItem.contentType, "MPEG-4 movie")
        
        // When choosing to save the video.
        context.send(viewAction: .menuAction(.save, item: mediaItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the video should be saved as a video in the user's photo library.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.type, .video)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.url, mediaItem.fileHandle?.url)
    }
    
    func testSaveFile() async throws {
        // Given a view model with a loaded file.
        setupViewModel(initialItemIndex: 2)
        try await loadInitialItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            XCTFail("There should be a current item")
            return
        }
        XCTAssertEqual(mediaItem.contentType, "PDF document")
        
        // When choosing to save the file.
        let deferred = deferFulfillment(context.viewState.previewControllerDriver) { $0.isExportFile }
        context.send(viewAction: .menuAction(.save, item: mediaItem))
        let exportAction = try await deferred.fulfill()
        
        guard case let .exportFile(file) = exportAction else {
            XCTFail("Unexpected action")
            return
        }
        
        // Then the binding should be set for the user to export the file to their specified location.
        XCTAssertFalse(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(file.url, mediaItem.fileHandle?.url)
    }
    
    // MARK: - Helpers
    
    private func loadInitialItem() async throws {
        let deferred = deferFulfillment(viewModel.state.previewControllerDriver) { $0.isItemLoaded }
        let initialItem = context.viewState.dataSource.previewController(QLPreviewController(),
                                                                         previewItemAt: context.viewState.dataSource.initialItemIndex)
        guard let initialPreviewItem = initialItem as? TimelineMediaPreviewItem.Media else {
            XCTFail("The initial item should be a media preview.")
            return
        }
        context.send(viewAction: .updateCurrentItem(.media(initialPreviewItem)))
        try await deferred.fulfill()
    }
    
    private func setupViewModel(initialItemIndex: Int = 0, photoLibraryAuthorizationDenied: Bool = false) {
        let initialItems = makeItems()
        timelineController = MockTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = initialItems
        
        mediaProvider = MediaProviderMock(configuration: .init())
        photoLibraryManager = PhotoLibraryManagerMock(.init(authorizationDenied: photoLibraryAuthorizationDenied))
        
        viewModel = TimelineMediaPreviewViewModel(initialItem: initialItems[initialItemIndex],
                                                  timelineViewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                            timelineController: timelineController),
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
                                 sender: .init(id: ""),
                                 content: .init(filename: "Important file.pdf",
                                                source: try? .init(url: .mockMXCFile, mimeType: "document/pdf"),
                                                fileSize: 2453,
                                                thumbnailSource: nil,
                                                contentType: .pdf))
        ]
    }
}
