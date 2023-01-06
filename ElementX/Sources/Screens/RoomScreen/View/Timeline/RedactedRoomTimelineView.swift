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

struct RedactedRoomTimelineView: View {
    let timelineItem: RedactedRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            HStack {
                Image(systemName: "trash")
                FormattedBodyText(text: timelineItem.text)
            }
        }
        .id(timelineItem.id)
    }
}

struct RedactedRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            RedactedRoomTimelineView(timelineItem: itemWith(text: ElementL10n.eventRedacted,
                                                            timestamp: "Later",
                                                            senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, senderId: String) -> RedactedRoomTimelineItem {
        RedactedRoomTimelineItem(id: UUID().uuidString,
                                 text: text,
                                 timestamp: timestamp,
                                 groupState: .single,
                                 isOutgoing: false,
                                 isEditable: false,
                                 senderId: senderId)
    }
}
