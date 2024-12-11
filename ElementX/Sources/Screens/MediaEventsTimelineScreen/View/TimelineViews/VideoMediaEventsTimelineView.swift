//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct VideoMediaEventsTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: VideoRoomTimelineItem
    
    var body: some View {
        thumbnail
            .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.commonVideo)
    }
    
    @ViewBuilder
    var thumbnail: some View {
        if let thumbnailSource = timelineItem.content.thumbnailInfo?.source {
            LoadableImage(mediaSource: thumbnailSource,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size,
                          mediaProvider: context?.mediaProvider) { imageView in
                imageView
                    .overlay { playIcon }
            } placeholder: {
                placeholder
            }
            .mediaGalleryTimelineAspectRatio(imageInfo: timelineItem.content.thumbnailInfo)
        } else {
            playIcon
        }
    }
    
    var playIcon: some View {
        Image(systemName: "play.circle.fill")
            .resizable()
            .frame(width: 50, height: 50)
            .background(.ultraThinMaterial, in: Circle())
            .foregroundColor(.white)
    }
    
    var placeholder: some View {
        Rectangle()
            .foregroundColor(.compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct VideoMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20.0) {
                VideoMediaEventsTimelineView(timelineItem: makeTimelineItem())
                VideoMediaEventsTimelineView(timelineItem: makeTimelineItem(isEdited: true))
                
                // Blurhash item?
                
                VideoMediaEventsTimelineView(timelineItem: makeTimelineItem(caption: "This is a great image 😎"))
                VideoMediaEventsTimelineView(timelineItem: makeTimelineItem(caption: "This is a great image with a really long multiline caption",
                                                                            isEdited: true))
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewLayout(.fixed(width: 390, height: 975))
        .padding(.bottom, 20)
    }
    
    private static func makeTimelineItem(caption: String? = nil, isEdited: Bool = false) -> VideoRoomTimelineItem {
        VideoRoomTimelineItem(id: .randomEvent,
                              timestamp: .mock,
                              isOutgoing: false,
                              isEditable: false,
                              canBeRepliedTo: true,
                              isThreaded: false,
                              sender: .init(id: "Bob"),
                              content: .init(filename: "video.mp4",
                                             caption: caption,
                                             videoInfo: .mockVideo,
                                             thumbnailInfo: .mockVideoThumbnail,
                                             blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"),
                              properties: .init(isEdited: isEdited))
    }
}
