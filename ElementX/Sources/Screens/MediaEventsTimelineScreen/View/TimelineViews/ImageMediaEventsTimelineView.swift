//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct ImageMediaEventsTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: ImageRoomTimelineItem
    
    var body: some View {
        loadableImage
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.commonImage)
    }
    
    @ViewBuilder
    private var loadableImage: some View {
        if timelineItem.content.contentType == .gif {
            LoadableImage(mediaSource: timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.imageInfo.size,
                          mediaProvider: context?.mediaProvider) {
                placeholder
            }
            .mediaGalleryTimelineAspectRatio(imageInfo: timelineItem.content.imageInfo)
        } else {
            LoadableImage(mediaSource: timelineItem.content.thumbnailInfo?.source ?? timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
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
            .foregroundColor(.compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct ImageMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20.0) {
                ImageMediaEventsTimelineView(timelineItem: makeTimelineItem())
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewLayout(.fixed(width: 390, height: 1200))
    }
    
    private static func makeTimelineItem(caption: String? = nil, isEdited: Bool = false) -> ImageRoomTimelineItem {
        ImageRoomTimelineItem(id: .randomEvent,
                              timestamp: .mock,
                              isOutgoing: false,
                              isEditable: false,
                              canBeRepliedTo: true,
                              isThreaded: false,
                              sender: .init(id: "Bob"),
                              content: .init(filename: "image.jpg",
                                             caption: caption,
                                             imageInfo: .mockImage,
                                             thumbnailInfo: .mockThumbnail,
                                             blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                                             contentType: .jpeg),
                              properties: .init(isEdited: isEdited))
    }
}
