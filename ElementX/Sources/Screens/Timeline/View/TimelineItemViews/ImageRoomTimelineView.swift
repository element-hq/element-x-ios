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
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            LoadableImage(mediaSource: source,
                          blurhash: timelineItem.content.blurhash,
                          mediaProvider: context.mediaProvider) {
                placeholder
            }
            .timelineMediaFrame(height: timelineItem.content.height,
                                aspectRatio: timelineItem.content.aspectRatio)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.commonImage)
        }
    }
    
    var source: MediaSourceProxy {
        guard timelineItem.content.contentType != .gif, let thumbnailSource = timelineItem.content.thumbnailSource else {
            return timelineItem.content.source
        }
        
        return thumbnailSource
    }
    
    var placeholder: some View {
        ZStack {
            Rectangle()
                .foregroundColor(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
                .opacity(0.3)
            
            ProgressView(L10n.commonLoading)
                .frame(maxWidth: .infinity)
        }
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
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some other image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Blurhashed image",
                                                                                     source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/gif"),
                                                                                     thumbnailSource: nil,
                                                                                     aspectRatio: 0.7,
                                                                                     blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                                                                                     contentType: .gif)))
        }
    }
}
