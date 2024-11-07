//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct VideoRoomTimelineView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    let timelineItem: VideoRoomTimelineItem
    
    private var hasMediaCaption: Bool { timelineItem.content.caption != nil }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 4) {
                thumbnail
                    .timelineMediaFrame(height: timelineItem.content.height,
                                        aspectRatio: timelineItem.content.aspectRatio)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L10n.commonVideo)
                    // This clip shape is distinct from the one in the styler as that one
                    // operates on the entire message so wouldn't round the bottom corners.
                    .clipShape(RoundedRectangle(cornerRadius: hasMediaCaption ? 6 : 0))
                
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
        if let thumbnailSource = timelineItem.content.thumbnailSource {
            LoadableImage(mediaSource: thumbnailSource,
                          mediaType: .timelineItem,
                          blurhash: timelineItem.content.blurhash,
                          mediaProvider: context.mediaProvider) { imageView in
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
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "video.mp4",
                                                                                     duration: 21,
                                                                                     source: nil,
                                                                                     thumbnailSource: nil)))

            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "other.mp4",
                                                                                     duration: 22,
                                                                                     source: nil,
                                                                                     thumbnailSource: nil)))
            
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "Blurhashed.mp4",
                                                                                     duration: 23,
                                                                                     source: nil,
                                                                                     thumbnailSource: nil,
                                                                                     aspectRatio: 0.7,
                                                                                     blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW")))
            
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "video.mp4",
                                                                                     caption: "This is a caption",
                                                                                     duration: 21,
                                                                                     source: nil,
                                                                                     thumbnailSource: nil)))
        }
    }
}
