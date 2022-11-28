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

struct FileRoomTimelineView: View {
    let timelineItem: FileRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.element.primaryContent)
                FormattedBodyText(text: timelineItem.text)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
        }
        .id(timelineItem.id)
    }
}

struct FileRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            FileRoomTimelineView(timelineItem: FileRoomTimelineItem(id: UUID().uuidString,
                                                                    text: "document.pdf",
                                                                    timestamp: "Now",
                                                                    inGroupState: .single,
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    senderId: "Bob",
                                                                    source: nil,
                                                                    thumbnailSource: nil))

            FileRoomTimelineView(timelineItem: FileRoomTimelineItem(id: UUID().uuidString,
                                                                    text: "document.docx",
                                                                    timestamp: "Now",
                                                                    inGroupState: .single,
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    senderId: "Bob",
                                                                    source: nil,
                                                                    thumbnailSource: nil))
            
            FileRoomTimelineView(timelineItem: FileRoomTimelineItem(id: UUID().uuidString,
                                                                    text: "document.txt",
                                                                    timestamp: "Now",
                                                                    inGroupState: .single,
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    senderId: "Bob",
                                                                    source: nil,
                                                                    thumbnailSource: nil))
        }
    }
}
