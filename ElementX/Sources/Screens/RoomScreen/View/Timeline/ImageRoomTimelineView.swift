//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftUI

struct ImageRoomTimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    let timelineItem: ImageRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            LoadableImage(mediaSource: source,
                          blurhash: timelineItem.content.blurhash,
                          imageProvider: context.imageProvider) {
                placeholder
            }
            .frame(maxHeight: min(300, max(100, timelineItem.content.height ?? .infinity)))
            .aspectRatio(timelineItem.content.aspectRatio, contentMode: .fit)
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

struct ImageRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        body
            .environmentObject(viewModel.context)
        body
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .init(timelineID: UUID().uuidString),
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .init(timelineID: UUID().uuidString),
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      content: .init(body: "Some other image", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/png"), thumbnailSource: nil)))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: .init(timelineID: UUID().uuidString),
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
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
