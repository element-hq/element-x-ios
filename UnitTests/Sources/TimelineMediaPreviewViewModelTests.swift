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
import Testing

@MainActor
struct TimelineMediaPreviewViewModelTests {
    var viewModel: TimelineMediaPreviewViewModel!
    var context: TimelineMediaPreviewViewModel.Context {
        viewModel.context
    }
    
    var mediaProvider: MediaProviderMock!
    var photoLibraryManager: PhotoLibraryManagerMock!
    var timelineController: TimelineControllerMock!
    
    @Test
    mutating func loadingItem() async throws {
        // Given a fresh view model.
        setupViewModel()
        #expect(!mediaProvider.loadFileFromSourceFilenameProgressCalled)
        #expect(context.viewState.currentItem == .media(context.viewState.dataSource.previewItems[0]))
        #expect(context.viewState.currentItemActions != nil)
        
        // When the preview controller sets the current item.
        try await loadInitialItem()
        
        // Then the view model should load the item and update its view state.
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCalled)
        #expect(context.viewState.currentItem == .media(context.viewState.dataSource.previewItems[0]))
        #expect(context.viewState.currentItemActions != nil)
    }
    
    @Test
    mutating func loadingItemFailure() async throws {
        // Given a fresh view model.
        setupViewModel()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        
        #expect(!mediaProvider.loadFileFromSourceFilenameProgressCalled)
        #expect(mediaItem == context.viewState.dataSource.previewItems[0])
        #expect(mediaItem.downloadError == nil)
        
        // When the preview controller sets an item that fails to load.
        mediaProvider.loadFileFromSourceFilenameProgressClosure = { _, _, _ in .failure(.failedRetrievingFile) }
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[0])))
        try await failure.fulfill()
        
        // Then the view model should load the item and update its view state.
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCalled)
        #expect(mediaItem == context.viewState.dataSource.previewItems[0])
        #expect(mediaItem.downloadError != nil)
    }
    
    @Test
    mutating func displayLoadIsNotDuplicated() async throws {
        // Given a fresh view model whose media downloads slowly.
        setupViewModel()
        let mediaItem = context.viewState.dataSource.previewItems[1]
        try await Task.sleep(for: .milliseconds(50)) // Let the initial item's own load settle.
        let loadsBefore = mediaProvider.loadFileFromSourceFilenameProgressCallsCount
        mediaProvider.loadFileFromSourceFilenameProgressClosure = { _, _, _ in
            try? await Task.sleep(for: .milliseconds(300))
            return .failure(.failedRetrievingFile)
        }
        
        // When QuickLook asks for the same page twice while its download is in flight (it rebuilds
        // pages as neighbours and placeholders land).
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(mediaItem)))
        try await Task.sleep(for: .milliseconds(50))
        context.send(viewAction: .updateCurrentItem(.media(mediaItem)))
        try await failure.fulfill()
        
        // Then the second request joins the first download rather than starting another.
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCallsCount == loadsBefore + 1)
    }
    
    @Test
    mutating func downloadProgress() async throws {
        // Given a fresh view model whose media downloads slowly, reporting its progress.
        setupViewModel()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        #expect(mediaItem.downloadProgress == nil)
        mediaProvider.loadFileFromSourceFilenameProgressClosure = { _, _, progress in
            await progress?(0.42)
            try? await Task.sleep(for: .milliseconds(200))
            return .failure(.failedRetrievingFile)
        }
        
        // When the preview controller sets the item.
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(mediaItem)))
        
        // Then the item shows the download's progress until the load ends.
        for _ in 0..<100 where mediaItem.downloadProgress == nil {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(mediaItem.downloadProgress == 0.42)
        try await failure.fulfill()
        #expect(mediaItem.downloadProgress == nil)
    }
    
    @Test
    mutating func swipingBetweenItems() async throws {
        // Given a view model with a loaded item.
        try await loadingItem()
        
        // When swiping to another item.
        let deferred = deferFulfillment(viewModel.state.previewControllerDriver) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[1])))
        try await deferred.fulfill()
        
        // Then the view model should load the item and update its view state.
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCallsCount == 2)
        #expect(context.viewState.currentItem == .media(context.viewState.dataSource.previewItems[1]))
        
        // When swiping back to the first item.
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[0])))
        try await failure.fulfill()
        
        // Then the view model should not need to load the item, but should still update its view state.
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCallsCount == 2)
        #expect(context.viewState.currentItem == .media(context.viewState.dataSource.previewItems[0]))
    }
    
    @Test
    mutating func loadingMoreItems() async throws {
        // Given a view model with a loaded item.
        try await loadingItem()
        #expect(timelineController.paginateBackwardsRequestSizeCallsCount == 0)
        
        // When swiping to a "loading more" item and there are more media items to load.
        timelineController.update(paginationState: .init(backward: .idle, forward: .endReached))
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.loading(.paginatingBackwards)))
        try await failure.fulfill()
        
        // Then there should no longer be a media preview and instead of loading any media, a pagination request should be made.
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCallsCount == 1)
        #expect(context.viewState.currentItem == .loading(.paginatingBackwards)) // Note: This item only changes when the preview controller handles the new items.
        #expect(timelineController.paginateBackwardsRequestSizeCallsCount == 1)
    }
    
    @Test
    mutating func pagination() async throws {
        // Given a view model with a loaded item.
        try await loadingItem()
        #expect(context.viewState.dataSource.previewItems.count == 3)
        
        // When more items are added via a back pagination.
        let deferred = deferFulfillment(context.viewState.dataSource.previewItemsPaginationPublisher) { _ in true }
        timelineController.setupBackPagination(responses: [makeItems()])
        _ = await timelineController.paginateBackwards(requestSize: 20)
        try await deferred.fulfill()
        
        // And the preview controller attempts to update the current item (now at a new index in the array but it hasn't changed in the data source).
        mediaProvider.loadFileFromSourceFilenameProgressClosure = { _, _, _ in .failure(.failedRetrievingFile) }
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(context.viewState.dataSource.previewItems[3])))
        try await failure.fulfill()
        
        // Then the current item shouldn't need to be reloaded.
        #expect(context.viewState.dataSource.previewItems.count == 6)
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCallsCount == 1)
    }
    
    @Test
    mutating func viewInRoomTimeline() async throws {
        // Given a view model with a loaded item.
        try await loadingItem()
        
        // When choosing to view the current item in the timeline.
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item.")
            return
        }
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .viewInRoomTimeline(mediaItem.timelineItem.id) }
        context.send(viewAction: .menuAction(.viewInRoomTimeline, item: mediaItem))
        
        // Then the action should be sent upwards to make this happen.
        try await deferred.fulfill()
    }
    
    @Test
    mutating func redactConfirmation() async throws {
        // Given a view model with a loaded item.
        try await loadingItem()
        #expect(context.redactConfirmationItem == nil)
        #expect(!timelineController.redactCalled)
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item.")
            return
        }
        
        // When choosing to show the item details.
        let deferredDriver = deferFulfillment(context.viewState.previewControllerDriver) { $0.isShowItemDetails }
        context.send(viewAction: .showItemDetails(mediaItem))
        
        // Then the details sheet should be presented.
        let action = try await deferredDriver.fulfill()
        guard case let .showItemDetails(mediaDetailsItem) = action else {
            Issue.record("The action should include the media item.")
            return
        }
        #expect(.media(mediaDetailsItem) == context.viewState.currentItem)
        
        // When choosing to redact the item.
        context.send(viewAction: .menuAction(.redact(isMedia: true), item: mediaItem))
        
        // Then the confirmation sheet should be presented.
        #expect(context.redactConfirmationItem == mediaItem)
        #expect(!timelineController.redactCalled)
        
        // When confirming the redaction.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        
        // The redaction runs in an unstructured task, so wait for the call rather than asserting after the dismiss.
        await waitForConfirmation { confirmation in
            timelineController.redactClosure = { _ in confirmation() }
            context.send(viewAction: .redactConfirmation(item: mediaItem))
        }
        
        // Then the item should be redacted and the view should be dismissed.
        try await deferred.fulfill()
    }
    
    @Test
    mutating func saveImage() async throws {
        // Given a view model with a loaded image.
        try await loadingItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        #expect(mediaItem.contentType == "JPEG image")
        
        // When choosing to save the image.
        context.send(viewAction: .menuAction(.downloadMedia, item: mediaItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the image should be saved as a photo to the user's photo library.
        #expect(photoLibraryManager.addResourceAtCalled)
        #expect(photoLibraryManager.addResourceAtReceivedArguments?.type == .photo)
        #expect(photoLibraryManager.addResourceAtReceivedArguments?.url == mediaItem.fileHandle?.url)
    }
    
    @Test
    mutating func saveImageWithoutAuthorization() async throws {
        // Given a view model with a loaded image where the user has denied access to the photo library.
        setupViewModel(photoLibraryAuthorizationDenied: true)
        try await loadInitialItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        #expect(mediaItem.contentType == "JPEG image")
        
        // When choosing to save the image.
        let deferred = deferFulfillment(context.viewState.previewControllerDriver) { $0.isAuthorizationRequired }
        context.send(viewAction: .menuAction(.downloadMedia, item: mediaItem))
        
        // Then the user should be prompted to allow access.
        try await deferred.fulfill()
        #expect(photoLibraryManager.addResourceAtCalled)
    }
    
    @Test
    mutating func saveVideo() async throws {
        // Given a view model with a loaded video.
        setupViewModel(initialItemIndex: 1)
        try await loadInitialItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        #expect(mediaItem.contentType == "MPEG-4 movie")
        
        // When choosing to save the video.
        context.send(viewAction: .menuAction(.downloadMedia, item: mediaItem))
        try await Task.sleep(for: .seconds(0.5))
        
        // Then the video should be saved as a video in the user's photo library.
        #expect(photoLibraryManager.addResourceAtCalled)
        #expect(photoLibraryManager.addResourceAtReceivedArguments?.type == .video)
        #expect(photoLibraryManager.addResourceAtReceivedArguments?.url == mediaItem.fileHandle?.url)
    }
    
    @Test
    mutating func saveFile() async throws {
        // Given a view model with a loaded file.
        setupViewModel(initialItemIndex: 2)
        try await loadInitialItem()
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        #expect(mediaItem.contentType == "PDF document")
        
        // When choosing to save the file.
        let deferred = deferFulfillment(context.viewState.previewControllerDriver) { $0.isExportFile }
        context.send(viewAction: .menuAction(.downloadMedia, item: mediaItem))
        let exportAction = try await deferred.fulfill()
        
        guard case let .exportFile(file) = exportAction else {
            Issue.record("Unexpected action")
            return
        }
        
        // Then the binding should be set for the user to export the file to their specified location.
        #expect(!photoLibraryManager.addResourceAtCalled)
        #expect(file.url == mediaItem.fileHandle?.url)
    }
    
    @Test
    mutating func safeItem() async throws {
        // Given a view model with a content scanner that reports the media as safe.
        setupViewModel(contentScannerService: ContentScannerServiceMock(.init(scanResult: true)))
        
        // When the preview controller sets the current item.
        try await loadInitialItem()
        
        // Then the media should be downloaded as usual.
        guard case .media = context.viewState.currentItem else {
            Issue.record("The item should be previewable")
            return
        }
        #expect(mediaProvider.loadFileFromSourceFilenameProgressCalled)
    }
    
    @Test
    mutating func unsafeItem() async throws {
        // Given a view model with a content scanner that reports the media as unsafe.
        setupViewModel(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        
        // When the preview controller sets the current item.
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(mediaItem)))
        try await failure.fulfill()
        
        // Then the media must not be downloaded and the failure should be reflected in the current item.
        #expect(!mediaProvider.loadFileFromSourceFilenameProgressCalled)
        #expect(context.viewState.currentItem == .contentScan(.init(media: mediaItem, state: .failure(.notSafe))))
        #expect(mediaItem.fileHandle == nil)
    }
    
    @Test
    mutating func failedScanItem() async throws {
        // Given a view model with a content scanner that fails to scan the media.
        let contentScannerService = ContentScannerServiceMock()
        contentScannerService.loadScanResultFromSourceClosure = { _ in .failure(.failedScanning) }
        setupViewModel(contentScannerService: contentScannerService)
        guard case let .media(mediaItem) = context.viewState.currentItem else {
            Issue.record("There should be a current item")
            return
        }
        
        // When the preview controller sets the current item.
        let failure = deferFailure(viewModel.state.previewControllerDriver, timeout: .seconds(1)) { $0.isItemLoaded }
        context.send(viewAction: .updateCurrentItem(.media(mediaItem)))
        try await failure.fulfill()
        
        // Then the media must not be downloaded and the failure should be reflected in the current item.
        #expect(!mediaProvider.loadFileFromSourceFilenameProgressCalled)
        #expect(context.viewState.currentItem == .contentScan(.init(media: mediaItem, state: .failure(.notFound))))
        #expect(mediaItem.fileHandle == nil)
    }
    
    // MARK: - Helpers
    
    private func loadInitialItem() async throws {
        let deferred = deferFulfillment(viewModel.state.previewControllerDriver) { $0.isItemLoaded }
        let initialItem = context.viewState.dataSource.previewController(QLPreviewController(),
                                                                         previewItemAt: context.viewState.dataSource.initialItemIndex)
        guard let initialPreviewItem = initialItem as? TimelineMediaPreviewItem.Media else {
            Issue.record("The initial item should be a media preview.")
            return
        }
        context.send(viewAction: .updateCurrentItem(.media(initialPreviewItem)))
        try await deferred.fulfill()
    }
    
    private mutating func setupViewModel(initialItemIndex: Int = 0,
                                         photoLibraryAuthorizationDenied: Bool = false,
                                         contentScannerService: ContentScannerServiceProtocol? = nil) {
        let initialItems = makeItems()
        timelineController = TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen), timelineItems: initialItems))
        
        mediaProvider = MediaProviderMock(.init())
        // No cached/loadable thumbnails: a thumbnail placeholder would itself drive `.itemLoaded`
        // (QuickLook refreshes the page for it) ~300ms in, which these tests read as the media landing.
        mediaProvider.imageFromSourceSizeClosure = { _, _ in nil }
        mediaProvider.loadImageRetryingOnReconnectionSizeClosure = { _, _ in Task { throw MediaProviderError.failedRetrievingImage } }
        photoLibraryManager = PhotoLibraryManagerMock(.init(authorizationDenied: photoLibraryAuthorizationDenied))
        
        viewModel = TimelineMediaPreviewViewModel(initialItem: initialItems[initialItemIndex],
                                                  timelineViewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                            timelineController: timelineController,
                                                                                            contentScannerService: contentScannerService),
                                                  mediaProvider: mediaProvider,
                                                  photoLibraryManager: photoLibraryManager,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appMediator: AppMediatorMock(),
                                                  appSettings: appSettings)
    }
    
    /// Neighbour preloading off: these tests assert the load of the current item alone (call counts,
    /// no `.itemLoaded` for items that weren't swiped to).
    private var appSettings: AppSettings {
        let appSettings = AppSettings.volatile()
        appSettings.preloadMediaInViewer = false
        return appSettings
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
