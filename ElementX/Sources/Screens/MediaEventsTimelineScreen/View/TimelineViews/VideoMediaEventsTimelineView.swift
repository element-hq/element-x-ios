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
            .foregroundColor(.compound.bgSubtleSecondary)
            .opacity(0.3)
    }
}

struct VideoMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        VideoMediaEventsTimelineView(timelineItem: makeTimelineItem())
            .frame(width: 100, height: 100)
            .environmentObject(viewModel.context)
            .environment(\.timelineContext, viewModel.context)
            .previewLayout(.sizeThatFits)
            .background(.black)
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
                                             videoInfo: .mockVideo,
                                             thumbnailInfo: .mockVideoThumbnail))
    }
}
