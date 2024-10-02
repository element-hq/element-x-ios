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
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            thumbnail
                .timelineMediaFrame(height: timelineItem.content.height,
                                    aspectRatio: timelineItem.content.aspectRatio)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.commonVideo)
        }
    }
    
    @ViewBuilder
    var thumbnail: some View {
        if let thumbnailSource = timelineItem.content.thumbnailSource {
            LoadableImage(mediaSource: thumbnailSource,
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
        ZStack {
            Rectangle()
                .foregroundColor(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
                .opacity(0.3)
            
            ProgressView(L10n.commonLoading)
                .frame(maxWidth: .infinity)
        }
    }
}

struct VideoRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some video", duration: 21, source: nil, thumbnailSource: nil)))

            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some other video", duration: 22, source: nil, thumbnailSource: nil)))
            
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: .random,
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      canBeRepliedTo: true,
                                                                      isThreaded: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Blurhashed video", duration: 23, source: nil, thumbnailSource: nil, aspectRatio: 0.7, blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW")))
        }
    }
}
