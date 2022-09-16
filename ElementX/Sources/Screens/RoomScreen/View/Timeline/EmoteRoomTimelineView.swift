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

struct EmoteRoomTimelineView: View {
    let timelineItem: EmoteRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            HStack(alignment: .top) {
                Image(systemName: "face.dashed").padding(.top, 1.0)
                if let attributedComponents = timelineItem.attributedComponents {
                    FormattedBodyText(isOutgoing: timelineItem.isOutgoing, attributedComponents: attributedComponents)
                } else {
                    FormattedBodyText(isOutgoing: timelineItem.isOutgoing, text: timelineItem.text)
                }
            }
        }
        .id(timelineItem.id)
    }
}

struct EmoteRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EmoteRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                         timestamp: "Now",
                                                         senderId: "Bob"))
            
            EmoteRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                         timestamp: "Later",
                                                         senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, senderId: String) -> EmoteRoomTimelineItem {
        EmoteRoomTimelineItem(id: UUID().uuidString,
                              text: text,
                              timestamp: timestamp,
                              shouldShowSenderDetails: true,
                              isOutgoing: false,
                              senderId: senderId)
    }
}
