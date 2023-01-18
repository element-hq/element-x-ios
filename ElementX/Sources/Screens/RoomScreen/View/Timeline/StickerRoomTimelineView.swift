//
// Copyright 2023 New Vector Ltd
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

struct StickerRoomTimelineView: View {
    let timelineItem: StickerRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let image = timelineItem.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
            } else if let blurhash = timelineItem.blurhash,
                      // Build a small blurhash image so that it's fast
                      let image = UIImage(blurHash: blurhash, size: .init(width: 10.0, height: 10.0)) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
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
        .accessibilityLabel(timelineItem.text)
    }
}

struct StickerRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            StickerRoomTimelineView(timelineItem: StickerRoomTimelineItem(id: UUID().uuidString,
                                                                          text: "Some image",
                                                                          timestamp: "Now",
                                                                          groupState: .single,
                                                                          isOutgoing: false,
                                                                          isEditable: false,
                                                                          sender: .init(id: "Bob"),
                                                                          imageURL: nil,
                                                                          image: UIImage(systemName: "photo")))
            
            StickerRoomTimelineView(timelineItem: StickerRoomTimelineItem(id: UUID().uuidString,
                                                                          text: "Some other image",
                                                                          timestamp: "Now",
                                                                          groupState: .single,
                                                                          isOutgoing: false,
                                                                          isEditable: false,
                                                                          sender: .init(id: "Bob"),
                                                                          imageURL: nil,
                                                                          image: nil))
            
            StickerRoomTimelineView(timelineItem: StickerRoomTimelineItem(id: UUID().uuidString,
                                                                          text: "Blurhashed image",
                                                                          timestamp: "Now",
                                                                          groupState: .single,
                                                                          isOutgoing: false,
                                                                          isEditable: false,
                                                                          sender: .init(id: "Bob"),
                                                                          imageURL: nil,
                                                                          image: nil,
                                                                          aspectRatio: 0.7,
                                                                          blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
        }
    }
}
