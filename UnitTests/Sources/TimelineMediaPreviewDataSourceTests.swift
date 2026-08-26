//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import QuickLook
import Testing

@MainActor
struct TimelineMediaPreviewDataSourceTests {
    var initialMediaItems: [EventBasedMessageTimelineItemProtocol]!
    var initialMediaViewStates: [RoomTimelineItemViewState]!
    let initialItemIndex = 2
    
    var initialPadding = 100
    let previewController = QLPreviewController()
    
    init() {
        initialMediaItems = newChunk()
        initialMediaViewStates = initialMediaItems.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
    }
    
    @Test
    func initialItems() throws {
        try assertInitialDataSource()
    }
    
    @Test
    func timelinePreviewFlattensGalleries() throws {
        // Given a timeline containing an image, a gallery of 2 attachments and a gallery of 3, one of
        // which is a file that belongs in the other timeline.
        let image = ImageRoomTimelineItem(id: .randomEvent,
                                          timestamp: .mock,
                                          isOutgoing: false,
                                          isEditable: false,
                                          canBeRepliedTo: true,
                                          sender: .init(id: "Bob"),
                                          content: .init(filename: "image.jpg", imageInfo: .mockImage, thumbnailInfo: nil, blurhash: nil))
        let firstGalleryItems: [GalleryItem] = [.mockImage(index: 0), .mockVideo(index: 1)]
        let secondGalleryItems: [GalleryItem] = [.mockImage(index: 0), .mockFile(index: 1), .mockImage(index: 2)]
        let timelineItems: [RoomTimelineItemProtocol] = [image,
                                                         makeGallery(items: firstGalleryItems),
                                                         makeGallery(items: secondGalleryItems)]
        let itemViewStates = timelineItems.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        
        // When opening the preview from the image, which isn't part of a gallery.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: itemViewStates,
                                                        initialItem: image,
                                                        paginationState: .initial,
                                                        allowedGalleryItemTypes: [.image, .video])
        
        // Then the galleries' visual attachments are browsable as though they were individual messages,
        // whilst the file is left to the timeline that shows those.
        let imageID = try #require(image.id.eventOrTransactionID)
        let expectedIDs: [MediaPreviewItemID] = [.timelineItem(imageID),
                                                 .galleryItem(firstGalleryItems[0].id),
                                                 .galleryItem(firstGalleryItems[1].id),
                                                 .galleryItem(secondGalleryItems[0].id),
                                                 .galleryItem(secondGalleryItems[2].id)]
        #expect(dataSource.previewItems.map(\.id) == expectedIDs)
        
        // …starting from the tapped image.
        #expect(dataSource.currentMediaItemID == .timelineItem(imageID))
    }
    
    @Test
    func galleryPreview() throws {
        // Given a gallery message whose attachments are a mix of media types.
        let items: [GalleryItem] = [.mockImage(index: 0), .mockFile(index: 1), .mockVideo(index: 2), .mockAudio(index: 3)]
        let gallery = makeGallery(items: items)
        
        // When opening the preview scoped to that gallery on the second attachment.
        let dataSource = TimelineMediaPreviewDataSource(galleryItem: gallery, initialIndex: 1)
        
        // Then it is self contained, holding every one of the attachments without filtering any of
        // them out and with no surrounding pagination…
        let expectedIDs: [MediaPreviewItemID] = items.map { .galleryItem($0.id) }
        #expect(dataSource.previewItems.map(\.id) == expectedIDs)
        #expect(dataSource.numberOfPreviewItems(in: previewController) == items.count)
        #expect(dataSource.initialItemIndex == 1)
        
        // …and the initial item is the tapped attachment.
        let media = try #require(dataSource.currentItem.mediaItem, "The current item should be a media item.")
        #expect(media.id == .galleryItem(items[1].id))
    }
    
    @Test
    func galleryPreviewIncludesNonPreviewableItems() throws {
        // Given a gallery whose first attachment is an unknown type (QuickLook shows its default screen).
        let items: [GalleryItem] = [
            .other(id: .mock(0), filename: "unknown.bin"),
            .mockImage(index: 1, filename: "image-1.jpg"),
            .mockImage(index: 2, filename: "image-2.jpg")
        ]
        let gallery = GalleryRoomTimelineItem(id: .randomEvent,
                                              timestamp: .mock,
                                              isOutgoing: false,
                                              isEditable: false,
                                              canBeRepliedTo: true,
                                              sender: .init(id: "Bob"),
                                              content: .init(body: "Gallery", caption: nil, items: items),
                                              properties: .init())
        
        // When tapping the first image (index 1 in the full items array).
        let dataSource = TimelineMediaPreviewDataSource(galleryItem: gallery, initialIndex: 1)
        
        // Then every attachment is kept — indices line up 1:1 — and the unknown item has no media source.
        #expect(dataSource.previewItems.count == 3)
        #expect(dataSource.previewItems[0].id == .galleryItem(items[0].id))
        #expect(dataSource.previewItems[0].mediaSource == nil)
        let media = try #require(dataSource.currentItem.mediaItem, "The current item should be a media item.")
        #expect(media.id == .galleryItem(items[1].id))
    }
    
    @Test
    func currentUpdateItem() throws {
        // Given a data source built with the initial items.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: initialMediaViewStates,
                                                        initialItem: initialMediaItems[initialItemIndex],
                                                        paginationState: .initial)
        
        // When a different item is displayed.
        let previewItem = try #require(dataSource.previewController(previewController, previewItemAt: 1 + initialPadding) as? TimelineMediaPreviewItem.Media,
                                       "A preview item should be found.")
        dataSource.updateCurrentItem(.media(previewItem))
        
        // Then the data source should reflect the change of item.
        #expect(dataSource.currentMediaItemID == previewItem.id, "The displayed item should be the initial item.")
        
        // When a loading item is displayed.
        guard let loadingItem = dataSource.previewController(previewController, previewItemAt: initialPadding - 1) as? TimelineMediaPreviewItem.Loading else {
            Issue.record("A loading item should be be returned.")
            return
        }
        dataSource.updateCurrentItem(.loading(loadingItem))
        
        // Then the data source should show a loading item
        #expect(dataSource.currentItem == .loading(loadingItem), "The displayed item should be the loading item.")
    }
    
    @Test
    func updatedItems() async throws {
        // Given a data source built with the initial items.
        let dataSource = try assertInitialDataSource()
        
        // When one of the items changes but no pagination has occurred.
        let deferred = deferFailure(dataSource.previewItemsPaginationPublisher, timeout: .seconds(1)) { _ in true }
        dataSource.updatePreviewItems(itemViewStates: initialMediaViewStates)
        
        // Then no pagination should be detected and none of the data should have changed.
        try await deferred.fulfill()
        
        let previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        let displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should not change.")
        
        #expect(dataSource.previewItems.count == initialMediaViewStates.count, "The number of items should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The padded number of items should not change.")
    }
    
    @Test
    func pagination() async throws {
        // Given a data source built with the initial items.
        let dataSource = try assertInitialDataSource()
        
        // When more items are loaded in a back pagination.
        var deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let backPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        var newViewStates = backPaginationChunk + initialMediaViewStates
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then the new items should be added but the displayed item should not change or move in the array.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
        
        // When more items are loaded in a forward pagination or sync.
        deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let forwardPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        newViewStates += forwardPaginationChunk
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then the new items should be added but the displayed item should not change or move in the array.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
    }
    
    @Test
    mutating func paginationLimits() async throws {
        // Given a data source with a small amount of padding remaining.
        initialPadding = 2
        let dataSource = try assertInitialDataSource()
        
        // When paginating backwards by more than the available padding.
        var deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let backPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        var newViewStates = backPaginationChunk + initialMediaViewStates
        #expect(newViewStates.count > initialPadding)
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then all the items should be added but the preview-able count shouldn't grow and displayed item should not change or move.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
        
        // When paginating forwards by more than the available padding.
        deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let forwardPaginationChunk = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        newViewStates += forwardPaginationChunk
        dataSource.updatePreviewItems(itemViewStates: newViewStates)
        
        // Then all the items should be added but the preview-able count shouldn't grow and displayed item should not change or move.
        try await deferred.fulfill()
        #expect(dataSource.previewItems.count == newViewStates.count, "The new items should be added.")
        
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should not change.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The number of items should not change")
    }
    
    @Test
    func emptyTimeline() async throws {
        // Given a data source built with no timeline items loaded.
        let initialItem = initialMediaItems[initialItemIndex]
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: [],
                                                        initialItem: initialItem,
                                                        initialPadding: initialPadding,
                                                        paginationState: .initial)
        
        // When the preview controller displays the data.
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                         "A preview item should be found.")
        
        // Then the preview controller should always show the initial item.
        #expect(dataSource.previewItems.count == 1, "The initial item should be in the preview items array.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        #expect(dataSource.initialItemIndex == initialPadding, "The initial item index should be padded for the preview controller.")
        
        #expect(displayedItem.id == initialItem.previewID, "The displayed item should be the initial item.")
        #expect(dataSource.currentMediaItemID == initialItem.previewID, "The current item should also be the initial item.")
        
        // When the timeline loads the initial items.
        let deferred = deferFulfillment(dataSource.previewItemsPaginationPublisher) { _ in true }
        let loadedItems = initialMediaItems.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        dataSource.updatePreviewItems(itemViewStates: loadedItems)
        try await deferred.fulfill()
        
        // Then the preview controller should still show the initial item with the other items loaded around it.
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                     "A preview item should be found.")
        
        #expect(dataSource.previewItems.count == initialMediaViewStates.count, "The preview items should now be loaded.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The item count should not change as the padding will be reduced.")
        #expect(dataSource.initialItemIndex == initialPadding, "The item index should not change.")
        
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should not change.")
    }
    
    @Test
    func timelineUpdateWithoutInitialItem() async throws {
        // Given a data source built with no timeline items loaded.
        let initialItem = initialMediaItems[initialItemIndex]
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: [],
                                                        initialItem: initialItem,
                                                        initialPadding: initialPadding,
                                                        paginationState: .initial)
        
        // When the preview controller displays the data.
        var previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        var displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                         "A preview item should be found.")
        
        // Then the preview controller should always show the initial item.
        #expect(dataSource.previewItems.count == 1, "The initial item should be in the preview items array.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        #expect(dataSource.initialItemIndex == initialPadding, "The initial item index should be padded for the preview controller.")
        
        #expect(displayedItem.id == initialItem.previewID, "The displayed item should be the initial item.")
        #expect(dataSource.currentMediaItemID == initialItem.previewID, "The current item should also be the initial item.")
        
        // When the timeline loads more items but still doesn't include the initial item.
        let failure = deferFailure(dataSource.previewItemsPaginationPublisher, timeout: .seconds(1)) { _ in true }
        let loadedItems = newChunk().map { RoomTimelineItemViewState(item: $0, groupStyle: .single) }
        dataSource.updatePreviewItems(itemViewStates: loadedItems)
        try await failure.fulfill()
        
        // Then the preview controller shouldn't update the available preview items.
        previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                     "A preview item should be found.")
        
        #expect(dataSource.previewItems.count == 1, "No new items should have been added to the array.")
        #expect(previewItemCount == 1 + (2 * initialPadding), "The initial item count should not change.")
        #expect(dataSource.initialItemIndex == initialPadding, "The initial item index should not change.")
        
        #expect(displayedItem.id == initialItem.previewID, "The displayed item should not change.")
        #expect(dataSource.currentMediaItemID == initialItem.previewID, "The current item not change.")
    }
    
    // MARK: Helpers
    
    private func makeGallery(items: [GalleryItem]) -> GalleryRoomTimelineItem {
        .init(id: .randomEvent,
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              sender: .init(id: "Bob"),
              content: .init(body: "Gallery", caption: nil, items: items),
              properties: .init())
    }
    
    func newChunk() -> [EventBasedMessageTimelineItemProtocol] {
        TimelineFixtures.mediaChunk
            .compactMap { $0 as? EventBasedMessageTimelineItemProtocol }
            .filter(\.supportsMediaCaption) // Voice messages can't be previewed (and don't support captions).
            .filter { !($0 is GalleryRoomTimelineItem) } // Galleries are previewed through their own data source.
    }
    
    @Test
    func endReachedCollapsesPhantomPadding() throws {
        // Given a loaded data source that hasn't yet seen a real (non-initial) pagination state.
        let dataSource = try assertInitialDataSource()
        let itemCount = initialMediaViewStates.count
        
        // When the forward side reaches the end of the timeline (backward still loadable).
        dataSource.paginationState = .init(backward: .idle, forward: .endReached)
        
        // Then only the forward phantom padding collapses, so QuickLook bounces at the newest item
        // whilst the older side keeps its padding to paginate into.
        #expect(dataSource.firstPreviewItemIndex == initialPadding)
        #expect(dataSource.lastPreviewItemIndex == initialPadding + itemCount - 1)
        #expect(dataSource.numberOfPreviewItems(in: previewController) == itemCount + initialPadding)
        
        // When the backward side also reaches the end.
        dataSource.paginationState = .init(backward: .endReached, forward: .endReached)
        
        // Then both sides collapse: the real items are the whole of QuickLook's content, so it
        // bounces natively at either end, and the current item survives the index shift.
        #expect(dataSource.firstPreviewItemIndex == 0)
        #expect(dataSource.lastPreviewItemIndex == itemCount - 1)
        #expect(dataSource.numberOfPreviewItems(in: previewController) == itemCount)
        let currentItem = try #require(dataSource.previewController(previewController, previewItemAt: initialItemIndex) as? TimelineMediaPreviewItem.Media)
        #expect(currentItem.id == initialMediaItems[initialItemIndex].previewID)
    }
    
    @Test
    func sentLocalEchoKeepsItsPage() async throws {
        // Given a viewer opened on an upload in flight: a local echo with a transaction ID.
        let uniqueID = TimelineItemIdentifier.UniqueID(UUID().uuidString)
        func makeUpload(id: TimelineItemIdentifier.EventOrTransactionID) -> ImageRoomTimelineItem {
            ImageRoomTimelineItem(id: .event(uniqueID: uniqueID, eventOrTransactionID: id),
                                  timestamp: .mock,
                                  isOutgoing: true,
                                  isEditable: false,
                                  canBeRepliedTo: false,
                                  sender: .init(id: "Alice"),
                                  content: .init(filename: "upload.jpg", imageInfo: .mockImage, thumbnailInfo: nil, blurhash: nil))
        }
        let localEcho = makeUpload(id: .transactionID("t1"))
        var items = newChunk()
        items.append(localEcho)
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: items.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) },
                                                        initialItem: localEcho,
                                                        paginationState: .initial)
        let page = try #require(dataSource.currentItem.mediaItem)
        #expect(page.id == .timelineItem(.transactionID("t1")))
        
        // When the upload completes and the timeline swaps the echo's transaction ID for its event ID.
        items[items.count - 1] = makeUpload(id: .eventID("$e1"))
        let deferred = deferFailure(dataSource.previewItemsPaginationPublisher, timeout: .seconds(1)) { _ in true }
        dataSource.updatePreviewItems(itemViewStates: items.map { RoomTimelineItemViewState(item: $0, groupStyle: .single) })
        try await deferred.fulfill()
        
        // Then the same page carries on under the new ID (its file came from the local media cache), nothing rebuilt.
        #expect(dataSource.currentItem.mediaItem === page)
        #expect(page.id == .timelineItem(.eventID("$e1")))
        #expect(dataSource.previewItems.map(\.id).last == .timelineItem(.eventID("$e1")))
        #expect(dataSource.previewItems.count == items.count)
    }
    
    @discardableResult
    private func assertInitialDataSource() throws -> TimelineMediaPreviewDataSource {
        // Given a data source built with the initial items.
        let dataSource = TimelineMediaPreviewDataSource(itemViewStates: initialMediaViewStates,
                                                        initialItem: initialMediaItems[initialItemIndex],
                                                        initialPadding: initialPadding,
                                                        paginationState: .initial)
        
        // When the preview controller displays the data.
        let previewItemCount = dataSource.numberOfPreviewItems(in: previewController)
        let displayedItem = try #require(dataSource.previewController(previewController, previewItemAt: dataSource.initialItemIndex) as? TimelineMediaPreviewItem.Media,
                                         "A preview item should be found.")
        
        // Then the preview controller should be showing the initial item and the data source should reflect this.
        #expect(dataSource.initialItemIndex == initialItemIndex + initialPadding, "The initial item index should be padded for the preview controller.")
        #expect(displayedItem.id == initialMediaItems[initialItemIndex].previewID, "The displayed item should be the initial item.")
        #expect(dataSource.currentMediaItemID == initialMediaItems[initialItemIndex].previewID, "The current item should also be the initial item.")
        
        #expect(dataSource.previewItems.count == initialMediaViewStates.count, "The initial count of preview items should be correct.")
        #expect(previewItemCount == initialMediaViewStates.count + (2 * initialPadding), "The initial item count should be padded for the preview controller.")
        
        return dataSource
    }
}

private extension TimelineMediaPreviewDataSource {
    var currentMediaItemID: MediaPreviewItemID? {
        currentItem.mediaItem?.id
    }
}

private extension EventBasedMessageTimelineItemProtocol {
    /// Test helper that derives the same preview ID used by `TimelineMediaPreviewItem.Media` —
    /// avoids reaching into the private encoding from the tests.
    var previewID: MediaPreviewItemID {
        TimelineMediaPreviewItem.Media(timelineItem: self).id
    }
}
