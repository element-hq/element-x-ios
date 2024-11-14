//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct ImageRoomTimelineView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    let timelineItem: ImageRoomTimelineItem
    
    var hasMediaCaption: Bool { timelineItem.content.caption != nil }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 4) {
                loadableImage
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L10n.commonImage)
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
    private var loadableImage: some View {
        if timelineItem.content.contentType == .gif {
            LoadableImage(mediaSource: timelineItem.content.source,
                          mediaType: .timelineItem,
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.size,
                          mediaProvider: context.mediaProvider) {
                placeholder
            }
            .timelineMediaFrame(height: timelineItem.content.thumbnailSize?.height,
                                aspectRatio: timelineItem.content.aspectRatio)
        } else {
            LoadableImage(mediaSource: timelineItem.content.thumbnailSource ?? timelineItem.content.source,
                          mediaType: .timelineItem,
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailSize ?? timelineItem.content.size,
                          mediaProvider: context.mediaProvider) {
                placeholder
            }
            .timelineMediaFrame(height: timelineItem.content.thumbnailSize?.height ?? timelineItem.content.size?.height,
                                aspectRatio: timelineItem.content.thumbnailAspectRatio ?? timelineItem.content.aspectRatio)
        }
    }
        
    private var placeholder: some View {
        Rectangle()
            .foregroundColor(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct ImageRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body
            .environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "image.jpg",
                                                                                     source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/jpg"),
                                                                                     thumbnailSource: nil)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "other.png",
                                                                                     source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"),
                                                                                     thumbnailSource: nil)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "Blurhashed.jpg",
                                                                                     source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/gif"),
                                                                                     aspectRatio: 0.7,
                                                                                     thumbnailSource: nil,
                                                                                     blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                                                                                     contentType: .gif)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .randomEvent,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(filename: "Blurhashed.jpg",
                                                                                     caption: "This is a great image 😎",
                                                                                     source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"),
                                                                                     size: .init(width: 50, height: 50),
                                                                                     aspectRatio: 1,
                                                                                     thumbnailSource: nil,
                                                                                     blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                                                                                     contentType: .gif)))
        }
    }
}
