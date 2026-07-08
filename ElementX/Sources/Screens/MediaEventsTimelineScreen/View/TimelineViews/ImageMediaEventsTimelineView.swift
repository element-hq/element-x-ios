//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ImageMediaEventsTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: ImageRoomTimelineItem
    
    var body: some View {
        ContentScanningView(contentScannerService: context?.contentScannerService,
                            mediaSource: timelineItem.content.imageInfo.source) {
            Color.clear // Let the image aspect fill in place
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    loadableImage
                }
                .clipped()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.commonImage)
        } scanningContent: {
            ScanningMediaEventsTimelineView()
        } unsafeContent: { failure in
            UnsafeMediaEventsTimelineView(failure: failure)
        }
    }
    
    @ViewBuilder
    private var loadableImage: some View {
        if timelineItem.content.contentType == .gif {
            LoadableImage(mediaSource: timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.imageInfo.size,
                          mediaProvider: context?.mediaProvider) {
                placeholder
            }
            .mediaGalleryTimelineAspectRatio(imageInfo: timelineItem.content.imageInfo)
        } else {
            LoadableImage(mediaSource: timelineItem.content.thumbnailInfo?.source ?? timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size ?? timelineItem.content.imageInfo.size,
                          mediaProvider: context?.mediaProvider) {
                placeholder
            }
            .mediaGalleryTimelineAspectRatio(imageInfo: timelineItem.content.thumbnailInfo ?? timelineItem.content.imageInfo)
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .foregroundColor(.compound.bgSubtleSecondary)
            .opacity(0.3)
    }
}

struct ImageMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static let scanningViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: nil)))
    static let unsafeViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
    
    static var previews: some View {
        ImageMediaEventsTimelineView(timelineItem: makeTimelineItem())
            .frame(width: 100, height: 100)
            .environmentObject(viewModel.context)
            .environment(\.timelineContext, viewModel.context)
            .previewLayout(.sizeThatFits)
            .background(.black)
        
        HStack(spacing: 16) {
            ImageMediaEventsTimelineView(timelineItem: makeTimelineItem())
                .frame(width: 100, height: 100)
                .environmentObject(scanningViewModel.context)
                .environment(\.timelineContext, scanningViewModel.context)
            
            ImageMediaEventsTimelineView(timelineItem: makeTimelineItem())
                .frame(width: 100, height: 100)
                .environmentObject(unsafeViewModel.context)
                .environment(\.timelineContext, unsafeViewModel.context)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Content Scanner")
    }
    
    private static func makeTimelineItem() -> ImageRoomTimelineItem {
        ImageRoomTimelineItem(id: .randomEvent,
                              timestamp: .mock,
                              isOutgoing: false,
                              isEditable: false,
                              canBeRepliedTo: true,
                              sender: .init(id: "Bob"),
                              content: .init(filename: "image.jpg",
                                             imageInfo: .mockImage,
                                             thumbnailInfo: .mockThumbnail,
                                             contentType: .jpeg))
    }
}
