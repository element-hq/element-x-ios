//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import UniformTypeIdentifiers

struct GalleryRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: GalleryRoomTimelineItem
    
    private var hasMediaCaption: Bool {
        timelineItem.content.caption?.isBlank == false
    }
    
    /// A gallery uses a vertical file-list layout when it contains any non-visual attachment
    /// (file or audio). A grid reads well for images/videos but not for documents.
    private var usesListLayout: Bool {
        timelineItem.content.items.contains { !$0.isImage && !$0.isVideo }
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 8) {
                if usesListLayout {
                    GalleryListView(items: timelineItem.content.items,
                                    mediaProvider: context?.mediaProvider,
                                    contentScannerService: context?.contentScannerService,
                                    onItemTap: tap)
                } else {
                    GalleryGridView(items: timelineItem.content.items,
                                    mediaProvider: context?.mediaProvider,
                                    contentScannerService: context?.contentScannerService,
                                    onItemTap: tap)
                }
                
                if hasMediaCaption {
                    if usesListLayout {
                        GalleryDivider()
                    }
                    caption
                }
            }
            .frame(width: GalleryGridView.groupWidth, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var caption: some View {
        if let attributedCaption = timelineItem.content.formattedCaption {
            FormattedBodyText(attributedString: attributedCaption,
                              trailingReservedSize: timelineItem.trailingReservedSize,
                              boostFontSize: timelineItem.shouldBoost)
        } else if let caption = timelineItem.content.caption {
            FormattedBodyText(text: caption,
                              trailingReservedSize: timelineItem.trailingReservedSize,
                              boostFontSize: timelineItem.shouldBoost)
        }
    }
    
    private func tap(index: Int) {
        context?.send(viewAction: .galleryItemTapped(itemID: timelineItem.id, index: index))
    }
}

// MARK: - Previews

struct GalleryRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    // A dedicated view model whose content scanner reports a different verdict per item, so a
    // single gallery can show safe, scanning and unsafe tiles side by side.
    static let mixedScanViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(perSourceScanResult: { source in
        switch mixedVerdict(for: source) {
        case .safe: true
        case .unsafe: false
        case .scanning: nil
        }
    })))
    
    static var previews: some View {
        preview(makeItem(itemCount: 1), viewModel).previewDisplayName("1 image")
        preview(makeItem(itemCount: 2), viewModel).previewDisplayName("2 images")
        preview(makeItem(itemCount: 3), viewModel).previewDisplayName("3 images")
        preview(makeItem(itemCount: 4), viewModel).previewDisplayName("4 images")
        preview(makeItem(itemCount: 5), viewModel).previewDisplayName("5 images")
        preview(makeItem(itemCount: 9, caption: "A trip to remember 🌅"), viewModel).previewDisplayName("6+ images with caption")
        preview(makeFileListItem(caption: "Quarterly reports"), viewModel).previewDisplayName("File list")
        preview(makeMixedScanItem(), mixedScanViewModel).previewDisplayName("Mixed content scan")
        preview(makeMixedScanFileListItem(), mixedScanViewModel).previewDisplayName("Mixed content scan (files)")
    }
    
    static func preview(_ item: GalleryRoomTimelineItem, _ viewModel: TimelineViewModel) -> some View {
        GalleryRoomTimelineView(timelineItem: item)
            .padding(20)
            .environmentObject(viewModel.context)
            .environment(\.timelineContext, viewModel.context)
    }
    
    private static func makeItem(itemCount: Int, caption: String? = nil) -> GalleryRoomTimelineItem {
        let items: [GalleryItem] = (0..<itemCount).map { index in
            index.isMultiple(of: 3)
                ? .mockVideo(index: index, filename: "clip-\(index).mp4")
                : .mockImage(index: index, filename: "image-\(index).jpg")
        }
        
        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Gallery (\(itemCount) items)",
                                                      caption: caption,
                                                      items: items),
                                       properties: .init())
    }
    
    private static func makeFileListItem(caption: String?) -> GalleryRoomTimelineItem {
        let items: [GalleryItem] = [
            .mockImage(index: 0, filename: "photo.jpg"),
            .mockFile(index: 1, filename: "report.pdf"),
            .mockAudio(index: 2, filename: "meeting.m4a")
        ]
        
        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Mixed gallery",
                                                      caption: caption,
                                                      items: items),
                                       properties: .init())
    }
    
    // MARK: Mixed content-scanner fixtures
    
    private nonisolated enum ScanVerdict { case safe, unsafe, scanning }
    
    /// The verdict for each tile of the mixed-scan gallery, keyed by position.
    private nonisolated static let mixedVerdicts: [ScanVerdict] = [.safe, .unsafe, .scanning, .safe, .unsafe]
    
    private nonisolated static func mixedSource(index: Int) -> MediaSourceProxy {
        // Safe tiles use the loadable mock image so they render a real thumbnail. Scanning/unsafe
        // tiles show a spinner or error instead of the image, so a synthetic source is fine — and
        // it gives the mock scanner a distinct URL to key its per-tile verdict off.
        switch mixedVerdicts[index] {
        case .safe:
            return ImageInfoProxy.mockImage.source
        case .unsafe, .scanning:
            // swiftlint:disable:next force_try force_unwrapping
            return try! MediaSourceProxy(url: URL(string: "mxc://preview.element.io/mixed-scan-\(index)")!, mimeType: "image/jpeg")
        }
    }
    
    private nonisolated static func mixedVerdict(for source: MediaSourceProxy) -> ScanVerdict {
        guard let index = mixedVerdicts.indices.first(where: { mixedSource(index: $0).url == source.url }) else {
            return .safe
        }
        return mixedVerdicts[index]
    }
    
    private static func makeMixedScanItem() -> GalleryRoomTimelineItem {
        let items: [GalleryItem] = mixedVerdicts.indices.map { index in
            .mockImage(index: index,
                       filename: "image-\(index).jpg",
                       source: mixedSource(index: index),
                       thumbnailSource: mixedSource(index: index))
        }
        
        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Gallery (5 items)",
                                                      caption: "Mixed scan states",
                                                      items: items),
                                       properties: .init())
    }
    
    /// A file list (no thumbnails) exercising a normal, an unsafe and a scanning row via the
    /// mixed-scan view model (indices 0/1/2 → safe/unsafe/scanning).
    private static func makeMixedScanFileListItem() -> GalleryRoomTimelineItem {
        let items: [GalleryItem] = [
            .mockFile(index: 0, filename: "report.zip", source: mixedSource(index: 0), contentType: .zip),
            .mockFile(index: 1, filename: "contract.pdf", source: mixedSource(index: 1)),
            .mockAudio(index: 2, filename: "meeting.m4a", source: mixedSource(index: 2))
        ]
        
        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Files",
                                                      caption: "Mixed scan states",
                                                      items: items),
                                       properties: .init())
    }
}
