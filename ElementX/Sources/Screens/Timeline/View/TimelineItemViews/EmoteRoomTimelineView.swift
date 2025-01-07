//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct EmoteRoomTimelineView: View, TextBasedRoomTimelineViewProtocol {
    let timelineItem: EmoteRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let attributedString = timelineItem.content.formattedBody {
                FormattedBodyText(attributedString: attributedString, additionalWhitespacesCount: timelineItem.additionalWhitespaces())
            } else {
                FormattedBodyText(text: timelineItem.content.body, additionalWhitespacesCount: timelineItem.additionalWhitespaces())
            }
        }
    }
}

struct EmoteRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EmoteRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                         timestamp: .mock,
                                                         senderId: "Bob"))
            
            EmoteRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                         timestamp: .mock,
                                                         senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: Date, senderId: String) -> EmoteRoomTimelineItem {
        EmoteRoomTimelineItem(id: .randomEvent,
                              timestamp: timestamp,
                              isOutgoing: false,
                              isEditable: false,
                              canBeRepliedTo: true,
                              isThreaded: false,
                              sender: .init(id: senderId),
                              content: .init(body: text))
    }
}
