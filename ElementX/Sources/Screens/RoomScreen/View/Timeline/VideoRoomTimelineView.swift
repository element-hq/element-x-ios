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

struct VideoRoomTimelineView: View {
    let timelineItem: VideoRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let image = timelineItem.image {
                thumbnail(with: image)
            } else if let blurhash = timelineItem.blurhash,
                      // Build a small blurhash image so that it's fast
                      let image = UIImage(blurHash: blurhash, size: .init(width: 10.0, height: 10.0)) {
                thumbnail(with: image)
            } else {
                ZStack {
                    Rectangle()
                        .foregroundColor(.element.systemGray6)
                        .opacity(0.3)
                    
                    ProgressView(ElementL10n.loading)
                        .frame(maxWidth: .infinity)
                }
                .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
            }
        }
        .animation(.elementDefault, value: timelineItem.image)
    }

    @ViewBuilder
    private func thumbnail(with image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
            Image(systemName: "play.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .background(.ultraThinMaterial, in: Circle())
                .foregroundColor(.white)
        }
    }
}

struct VideoRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Some video",
                                                                      timestamp: "Now",
                                                                      groupState: .single,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      senderId: "Bob",
                                                                      duration: 21,
                                                                      source: nil,
                                                                      thumbnailSource: nil,
                                                                      image: UIImage(systemName: "photo")))

            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Some other video",
                                                                      timestamp: "Now",
                                                                      groupState: .single,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      senderId: "Bob",
                                                                      duration: 22,
                                                                      source: nil,
                                                                      thumbnailSource: nil,
                                                                      image: nil))
            
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Blurhashed video",
                                                                      timestamp: "Now",
                                                                      groupState: .single,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      senderId: "Bob",
                                                                      duration: 23,
                                                                      source: nil,
                                                                      thumbnailSource: nil,
                                                                      image: nil,
                                                                      aspectRatio: 0.7,
                                                                      blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
        }
    }
}
