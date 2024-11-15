//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct StickerRoomTimelineView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    let timelineItem: StickerRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            LoadableImage(url: timelineItem.imageInfo.source.url,
                          mediaType: .timelineItem,
                          blurhash: timelineItem.blurhash,
                          size: timelineItem.imageInfo.size,
                          mediaProvider: context.mediaProvider) {
                placeholder
            }
            .timelineMediaFrame(height: timelineItem.imageInfo.size?.height,
                                aspectRatio: timelineItem.imageInfo.aspectRatio)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(L10n.commonSticker), \(timelineItem.body)")
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .foregroundColor(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct StickerRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            StickerRoomTimelineView(timelineItem: StickerRoomTimelineItem(id: .randomEvent,
                                                                          body: "Some image",
                                                                          timestamp: "Now",
                                                                          isOutgoing: false,
                                                                          isEditable: false,
                                                                          canBeRepliedTo: true,
                                                                          sender: .init(id: "Bob"),
                                                                          imageInfo: .mockImage))
            
            StickerRoomTimelineView(timelineItem: StickerRoomTimelineItem(id: .randomEvent,
                                                                          body: "Some other image",
                                                                          timestamp: "Now",
                                                                          isOutgoing: false,
                                                                          isEditable: false,
                                                                          canBeRepliedTo: true,
                                                                          sender: .init(id: "Bob"),
                                                                          imageInfo: .mockImage))
            
            StickerRoomTimelineView(timelineItem: StickerRoomTimelineItem(id: .randomEvent,
                                                                          body: "Blurhashed image",
                                                                          timestamp: "Now",
                                                                          isOutgoing: false,
                                                                          isEditable: false,
                                                                          canBeRepliedTo: true,
                                                                          sender: .init(id: "Bob"),
                                                                          imageInfo: .mockImage,
                                                                          blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
        }
    }
}
