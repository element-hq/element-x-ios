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

struct NoticeRoomTimelineView: View, TextBasedRoomTimelineViewProtocol {
    let timelineItem: NoticeRoomTimelineItem
    @Environment(\.timelineStyle) var timelineStyle
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            // Don't use RoomTimelineViewLabelStyle with FormattedBodyText as the formatted text
            // adds additional padding so the spacing between the icon and text is inconsistent.
            
            // Spacing: 6 = label spacing - formatted text padding
            
            HStack(alignment: .firstTextBaseline, spacing: 6.0) {
                Image(systemName: "info.bubble").padding(.top, 2.0)
                    .foregroundColor(.compound.iconSecondary)
                
                if let attributedString = timelineItem.content.formattedBody {
                    FormattedBodyText(attributedString: attributedString, additionalWhitespacesCount: additionalWhitespaces)
                } else {
                    FormattedBodyText(text: timelineItem.content.body, additionalWhitespacesCount: additionalWhitespaces)
                }
            }
            .padding(.leading, 4) // Trailing padding is provided by FormattedBodyText
        }
    }
}

struct NoticeRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        body
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            NoticeRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                          timestamp: "Now",
                                                          senderId: "Bob"))
            
            NoticeRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                          timestamp: "Later",
                                                          senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, senderId: String) -> NoticeRoomTimelineItem {
        NoticeRoomTimelineItem(id: .init(timelineID: UUID().uuidString),
                               timestamp: timestamp,
                               isOutgoing: false,
                               isEditable: false,
                               sender: .init(id: senderId),
                               content: .init(body: text))
    }
}
