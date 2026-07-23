//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
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
    
    /// A gallery falls back to a vertical file-list layout when any of its items lacks a thumbnail
    /// (typically audio or generic files). Mixed galleries (image/video + file) also use the list
    /// — a grid of mostly-icons looks worse than a tidy list.
    private var usesListLayout: Bool {
        timelineItem.content.items.contains { !$0.hasThumbnail }
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 8) {
                if usesListLayout {
                    GalleryListView(items: timelineItem.content.items,
                                    uniqueID: timelineItem.id.uniqueID,
                                    mediaProvider: context?.mediaProvider,
                                    contentScannerService: context?.contentScannerService) { index in
                        tap(index: index)
                    }
                } else {
                    GalleryGridView(items: timelineItem.content.items,
                                    uniqueID: timelineItem.id.uniqueID,
                                    mediaProvider: context?.mediaProvider,
                                    contentScannerService: context?.contentScannerService) { index in
                        tap(index: index)
                    }
                }
                
                if hasMediaCaption {
                    if usesListLayout {
                        GalleryListView.galleryDivider
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
    static let mixedScanViewModel: TimelineViewModel = {
        let service = ContentScannerServiceMock()
        service.scanResultFromSourceClosure = { source in
            switch mixedVerdict(for: source) {
            case .safe: return true
            case .unsafe: return false
            case .scanning: return nil
            }
        }
        service.loadScanResultFromSourceClosure = { source in
            switch mixedVerdict(for: source) {
            case .safe:
                return .success(true)
            case .unsafe:
                return .success(false)
            case .scanning:
                try? await Task.sleep(for: .seconds(3600)) // Never resolves, so the scanning state stays visible.
                return .failure(.failedScanning)
            }
        }
        return TimelineViewModel.mock(contentScannerService: service)
    }()
    
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
            let isVideo = index.isMultiple(of: 3)
            return GalleryItem(id: "preview-\(index)",
                               filename: isVideo ? "clip-\(index).mp4" : "image-\(index).jpg",
                               kind: isVideo ? .video : .image,
                               mediaSource: ImageInfoProxy.mockImage.source,
                               thumbnailSource: ImageInfoProxy.mockThumbnail.source,
                               size: .init(width: 1920, height: 1080),
                               blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                               duration: isVideo ? 42 : nil,
                               contentType: isVideo ? .mpeg4Movie : .jpeg)
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
            GalleryItem(id: "preview-image",
                        filename: "photo.jpg",
                        kind: .image,
                        mediaSource: ImageInfoProxy.mockImage.source,
                        thumbnailSource: ImageInfoProxy.mockThumbnail.source,
                        size: .init(width: 1920, height: 1080),
                        blurhash: nil,
                        duration: nil,
                        contentType: .jpeg),
            GalleryItem(id: "preview-pdf",
                        filename: "report.pdf",
                        kind: .file,
                        mediaSource: nil,
                        thumbnailSource: nil,
                        size: nil,
                        blurhash: nil,
                        duration: nil,
                        contentType: .pdf),
            GalleryItem(id: "preview-audio",
                        filename: "meeting.m4a",
                        kind: .audio,
                        mediaSource: nil,
                        thumbnailSource: nil,
                        size: nil,
                        blurhash: nil,
                        duration: 65,
                        contentType: .mpeg4Audio)
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
            GalleryItem(id: "mixed-\(index)",
                        filename: "image-\(index).jpg",
                        kind: .image,
                        mediaSource: mixedSource(index: index),
                        thumbnailSource: mixedSource(index: index),
                        size: .init(width: 1920, height: 1080),
                        blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                        duration: nil,
                        contentType: .jpeg)
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
            GalleryItem(id: "mixed-file-0", filename: "report.zip", kind: .file,
                        mediaSource: mixedSource(index: 0), thumbnailSource: nil,
                        size: nil, blurhash: nil, duration: nil, contentType: .zip),
            GalleryItem(id: "mixed-file-1", filename: "contract.pdf", kind: .file,
                        mediaSource: mixedSource(index: 1), thumbnailSource: nil,
                        size: nil, blurhash: nil, duration: nil, contentType: .pdf),
            GalleryItem(id: "mixed-file-2", filename: "meeting.m4a", kind: .audio,
                        mediaSource: mixedSource(index: 2), thumbnailSource: nil,
                        size: nil, blurhash: nil, duration: nil, contentType: .mpeg4Audio)
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
