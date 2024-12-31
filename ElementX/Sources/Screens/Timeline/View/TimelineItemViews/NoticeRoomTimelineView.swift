//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct NoticeRoomTimelineView: View, TextBasedRoomTimelineViewProtocol {
    let timelineItem: NoticeRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            // Don't use RoomTimelineViewLabelStyle with FormattedBodyText as the formatted text
            // adds additional padding so the spacing between the icon and text is inconsistent.
            
            // Spacing: 6 = label spacing - formatted text padding
            
            Label {
                if let attributedString = timelineItem.content.formattedBody {
                    FormattedBodyText(attributedString: attributedString, additionalWhitespacesCount: timelineItem.additionalWhitespaces())
                } else {
                    FormattedBodyText(text: timelineItem.content.body, additionalWhitespacesCount: timelineItem.additionalWhitespaces())
                }
            } icon: {
                CompoundIcon(\.info, size: .small, relativeTo: .compound.bodyLG)
                    .foregroundColor(.compound.iconSecondary)
            }
            .labelStyle(.custom(spacing: 6.0, alignment: .top))
            .padding(.leading, 4) // Trailing padding is provided by FormattedBodyText
        }
    }
}

struct NoticeRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            NoticeRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                          timestamp: .mock,
                                                          senderId: "Bob"))
            
            NoticeRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                          timestamp: .mock,
                                                          senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: Date, senderId: String) -> NoticeRoomTimelineItem {
        NoticeRoomTimelineItem(id: .randomEvent,
                               timestamp: timestamp,
                               isOutgoing: false,
                               isEditable: false,
                               canBeRepliedTo: true,
                               isThreaded: false,
                               sender: .init(id: senderId),
                               content: .init(body: text))
    }
}
