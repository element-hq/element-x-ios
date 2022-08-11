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

struct TextRoomTimelineView: View {
    let timelineItem: TextRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let attributedComponents = timelineItem.attributedComponents {
                FormattedBodyText(attributedComponents: attributedComponents)
            } else {
                Text(timelineItem.text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
        }
        .id(timelineItem.id)
    }
}

struct TextRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            TextRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                        timestamp: "Now",
                                                        shouldShowSenderDetails: true,
                                                        isOutgoing: false,
                                                        senderId: "Bob"))

            TextRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                        timestamp: "Later",
                                                        shouldShowSenderDetails: true,
                                                        isOutgoing: true,
                                                        senderId: "Anne"))

            TextRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                        timestamp: "Now",
                                                        shouldShowSenderDetails: true,
                                                        isOutgoing: false,
                                                        senderId: "Bob"))
                .timelineStyle(.plain)

            TextRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                        timestamp: "Later",
                                                        shouldShowSenderDetails: true,
                                                        isOutgoing: true,
                                                        senderId: "Anne"))
                .timelineStyle(.plain)
        }
        .padding(.horizontal, 8)
    }
    
    private static func itemWith(text: String, timestamp: String, shouldShowSenderDetails: Bool, isOutgoing: Bool, senderId: String) -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: text,
                             timestamp: timestamp,
                             shouldShowSenderDetails: shouldShowSenderDetails,
                             isOutgoing: isOutgoing,
                             senderId: senderId)
    }
}
