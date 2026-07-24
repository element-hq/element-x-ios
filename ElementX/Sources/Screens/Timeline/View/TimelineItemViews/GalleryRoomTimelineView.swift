//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: GalleryRoomTimelineItem
    
    private var hasMediaCaption: Bool {
        timelineItem.content.caption?.isBlank == false
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 8) {
                GalleryGridView(items: timelineItem.content.items,
                                mediaProvider: context?.mediaProvider,
                                contentScannerService: context?.contentScannerService) { _ in
                    // Tapping to open the full-screen preview lands in a follow-up.
                }
                
                if hasMediaCaption {
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
}

// MARK: - Previews

struct GalleryRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    // Fixed sources keyed by the mock scanner below. Safe is loadable (real thumbnail); others just need a distinct URL.
    static let safeSource = ImageInfoProxy.mockImage.source
    // swiftlint:disable force_try force_unwrapping
    static let unsafeSource = try! MediaSourceProxy(url: URL(string: "mxc://preview.element.io/unsafe")!, mimeType: "image/jpeg")
    static let scanningSource = try! MediaSourceProxy(url: URL(string: "mxc://preview.element.io/scanning")!, mimeType: "image/jpeg")
    // swiftlint:enable force_try force_unwrapping
    
    static let mixedScanViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(perSourceScanResult: { source in
        if source.url == unsafeSource.url {
            false
        } else if source.url == scanningSource.url {
            nil
        } else {
            true
        }
    })))
    
    static var previews: some View {
        preview(makeItem(itemCount: 1), viewModel).previewDisplayName("1 image")
        preview(makeItem(itemCount: 2), viewModel).previewDisplayName("2 images")
        preview(makeItem(itemCount: 3), viewModel).previewDisplayName("3 images")
        preview(makeItem(itemCount: 4), viewModel).previewDisplayName("4 images")
        preview(makeItem(itemCount: 5), viewModel).previewDisplayName("5 images")
        preview(makeItem(itemCount: 9, caption: "A trip to remember 🌅"), viewModel).previewDisplayName("6+ images with caption")
        preview(makeMixedScanItem(), mixedScanViewModel).previewDisplayName("Mixed content scan")
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
    
    private static func makeMixedScanItem() -> GalleryRoomTimelineItem {
        // >maxVisible items with the overflow tile (index 4) unsafe, to show "+N" over a failed scan.
        let sources = [safeSource, unsafeSource, scanningSource, safeSource, unsafeSource, safeSource, safeSource]
        let items: [GalleryItem] = sources.enumerated().map { index, source in
            .mockImage(index: index, filename: "image-\(index).jpg", source: source, thumbnailSource: source)
        }
        
        return GalleryRoomTimelineItem(id: .randomEvent,
                                       timestamp: .mock,
                                       isOutgoing: false,
                                       isEditable: false,
                                       canBeRepliedTo: true,
                                       sender: .init(id: "Bob"),
                                       content: .init(body: "Gallery (\(sources.count) items)",
                                                      caption: "Mixed scan states",
                                                      items: items),
                                       properties: .init())
    }
}
