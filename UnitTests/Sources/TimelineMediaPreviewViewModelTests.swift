//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    var photoLibraryManager: PhotoLibraryManagerMock!
    var timelineController: MockRoomTimelineController!
    
    func testLoadingItem() async throws {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
        
        // When the preview controller sets the current item.
        try await loadInitialItem()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItemActions)
    }
    
    func testLoadingItemFailure() async throws {
        // Given a fresh view model.
        setupViewModel()
        XCTAssertFalse(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNil(context.viewState.currentItem.downloadError)
        
        // When the preview controller sets an item that fails to load.
        mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
        let failure = deferFailure(viewModel.state.fileLoadedPublisher, timeout: 1) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.previewItems[0]))
        try await failure.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertTrue(mediaProvider.loadFileFromSourceFilenameCalled)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
        XCTAssertNotNil(context.viewState.currentItem.downloadError)
    }
    
    func testSwipingBetweenItems() async throws {
        // Given a view model with a loaded item.
        try await testLoadingItem()
        
        // When swiping to another item.
        let deferred = deferFulfillment(viewModel.state.fileLoadedPublisher) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.previewItems[1]))
        try await deferred.fulfill()
        
        // Then the view model should load the item and update its view state.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 2)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[1])
        
        // When swiping back to the first item.
        let failure = deferFailure(viewModel.state.fileLoadedPublisher, timeout: 1) { _ in true }
        context.send(viewAction: .updateCurrentItem(context.viewState.previewItems[0]))
        try await failure.fulfill()
        
        // Then the view model should not need to load the item, but should still update its view state.
        XCTAssertEqual(mediaProvider.loadFileFromSourceFilenameCallsCount, 2)
        XCTAssertEqual(context.viewState.currentItem, context.viewState.previewItems[0])
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
    
    func testSaveImage() async throws {
        // Given a view model with a loaded image.
        try await testLoadingItem()
        XCTAssertEqual(viewModel.state.currentItem.contentType, "JPEG image")
        
        // When choosing to save the image.
        let item = context.viewState.currentItem
        context.send(viewAction: .saveCurrentItem)
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the image should be saved as a photo to the user's photo library.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.type, .photo)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.url, item.fileHandle?.url)
    }
    
    func testSaveImageWithoutAuthorization() async throws {
        // Given a view model with a loaded image where the user has denied access to the photo library.
        setupViewModel(photoLibraryAuthorizationDenied: true)
        try await loadInitialItem()
        XCTAssertEqual(viewModel.state.currentItem.contentType, "JPEG image")
        
        // When choosing to save the image.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .saveCurrentItem)
        try await deferred.fulfill()
        
        // Then the user should be prompted to allow access.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(context.alertInfo?.id, .authorizationRequired)
    }
    
    func testSaveVideo() async throws {
        // Given a view model with a loaded video.
        setupViewModel(initialItemIndex: 1)
        try await loadInitialItem()
        XCTAssertEqual(viewModel.state.currentItem.contentType, "MPEG-4 movie")
        
        // When choosing to save the video.
        let item = context.viewState.currentItem
        context.send(viewAction: .saveCurrentItem)
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the video should be saved as a video in the user's photo library.
        XCTAssertTrue(photoLibraryManager.addResourceAtCalled)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.type, .video)
        XCTAssertEqual(photoLibraryManager.addResourceAtReceivedArguments?.url, item.fileHandle?.url)
    }
    
    func testSaveFile() async throws {
        // Given a view model with a loaded file.
        setupViewModel(initialItemIndex: 2)
        try await loadInitialItem()
        XCTAssertEqual(viewModel.state.currentItem.contentType, "PDF document")
        
        // When choosing to save the file.
        let item = context.viewState.currentItem
        context.send(viewAction: .saveCurrentItem)
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the binding should be set for the user to export the file to their specified location.
        XCTAssertFalse(photoLibraryManager.addResourceAtCalled)
        XCTAssertNotNil(context.fileToExport)
        XCTAssertEqual(context.fileToExport?.url, item.fileHandle?.url)
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
        context.send(viewAction: .updateCurrentItem(context.viewState.previewItems[context.viewState.initialItemIndex]))
        try await deferred.fulfill()
    }
    
    @Namespace private var testNamespace
    
    private func setupViewModel(initialItemIndex: Int = 0, photoLibraryAuthorizationDenied: Bool = false) {
        timelineController = MockRoomTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = items
        
        mediaProvider = MediaProviderMock(configuration: .init())
        photoLibraryManager = PhotoLibraryManagerMock(.init(authorizationDenied: photoLibraryAuthorizationDenied))
        
        viewModel = TimelineMediaPreviewViewModel(context: .init(item: items[initialItemIndex],
                                                                 viewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                                   timelineController: timelineController),
                                                                 namespace: testNamespace),
                                                  mediaProvider: mediaProvider,
                                                  photoLibraryManager: photoLibraryManager,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appMediator: AppMediatorMock())
    }
    
    private let items: [EventBasedMessageTimelineItemProtocol] = [
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
