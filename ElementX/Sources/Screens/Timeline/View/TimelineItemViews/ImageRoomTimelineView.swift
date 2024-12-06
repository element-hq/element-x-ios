//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct ImageRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
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
    private var loadableImage: some View {
        if timelineItem.content.contentType == .gif {
            LoadableImage(mediaSource: timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.imageInfo.size,
                          mediaProvider: context?.mediaProvider) {
                placeholder
            }
            .timelineMediaFrame(imageInfo: timelineItem.content.imageInfo)
        } else {
            LoadableImage(mediaSource: timelineItem.content.thumbnailInfo?.source ?? timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size ?? timelineItem.content.imageInfo.size,
                          mediaProvider: context?.mediaProvider) {
                placeholder
            }
            .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo ?? timelineItem.content.imageInfo)
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
        ScrollView {
            VStack(spacing: 20.0) {
                ImageRoomTimelineView(timelineItem: makeTimelineItem())
                ImageRoomTimelineView(timelineItem: makeTimelineItem(isEdited: true))
                
                // Blur hashed item?
                
                ImageRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is a great image 😎"))
                ImageRoomTimelineView(timelineItem: makeTimelineItem(caption: "This is a great image with a really long multiline caption.",
                                                                     isEdited: true))
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewLayout(.fixed(width: 390, height: 1200))
        .padding(.bottom, 20)
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
