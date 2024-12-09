//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct VideoRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: VideoRoomTimelineItem
    
    private var hasMediaCaption: Bool { timelineItem.content.caption != nil }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 4) {
                thumbnail
                    .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L10n.commonVideo)
                    // This clip shape is distinct from the one in the styler as that one
                    // operates on the entire message so wouldn't round the bottom corners.
                    .clipShape(RoundedRectangle(cornerRadius: hasMediaCaption ? 6 : 0))
                    .onTapGesture {
                        context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                    }
                
                if let attributedCaption = timelineItem.content.formattedCaption {
                    FormattedBodyText(attributedString: attributedCaption,
                                      additionalWhitespacesCount: timelineItem.additionalWhitespaces(),
                                      boostEmojiSize: true)
                } else if let caption = timelineItem.content.caption {
                    FormattedBodyText(text: caption,
                                      additionalWhitespacesCount: timelineItem.additionalWhitespaces(),
                                      boostEmojiSize: true)
                }
            }
        }
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
            .foregroundColor(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct VideoRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20.0) {
                VideoRoomTimelineView(timelineItem: makeTimelineItem())
                VideoRoomTimelineView(timelineItem: makeTimelineItem(isEdited: true))
                
                // Blurhash item?
                
                VideoRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is a great image 😎"))
                VideoRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is a great image with a really long multiline caption",
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
