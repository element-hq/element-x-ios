//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct TextRoomTimelineView: View, TextBasedRoomTimelineViewProtocol {
    let timelineItem: TextRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let attributedString = timelineItem.content.formattedBody {
                FormattedBodyText(attributedString: attributedString,
                                  additionalWhitespacesCount: timelineItem.additionalWhitespaces(),
                                  boostEmojiSize: true)
            } else {
                FormattedBodyText(text: timelineItem.body,
                                  additionalWhitespacesCount: timelineItem.additionalWhitespaces(),
                                  boostEmojiSize: true)
            }
        }
    }
}

struct TextRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
            .previewDisplayName("Bubble")
        body
            .environmentObject(viewModel.context)
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Bubble RTL")
    }
    
    static var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20.0) {
                TextRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                            timestamp: "Now",
                                                            isOutgoing: false,
                                                            senderId: "Bob"))
                
                TextRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                            timestamp: "Later",
                                                            isOutgoing: true,
                                                            senderId: "Anne"))
                
                TextRoomTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                            timestamp: "Now",
                                                            isOutgoing: false,
                                                            senderId: "Bob"))
                
                TextRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                            timestamp: "Later",
                                                            isOutgoing: true,
                                                            senderId: "Anne"))
                
                TextRoomTimelineView(timelineItem: itemWith(text: "טקסט אחר",
                                                            timestamp: "Later",
                                                            isOutgoing: true,
                                                            senderId: "Anne"))
                
                TextRoomTimelineView(timelineItem: itemWith(html: "<ol><li>First item</li><li>Second item</li><li>Third item</li></ol>",
                                                            timestamp: "Later",
                                                            isOutgoing: true,
                                                            senderId: "Anne"))
                
                TextRoomTimelineView(timelineItem: itemWith(html: "<ol><li>פריט ראשון</li><li>הפריט השני</li><li>פריט שלישי</li></ol>",
                                                            timestamp: "Later",
                                                            isOutgoing: true,
                                                            senderId: "Anne"))
            }
        }
    }
    
    private static func itemWith(text: String, timestamp: String, isOutgoing: Bool, senderId: String) -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: .random,
                             timestamp: timestamp,
                             isOutgoing: isOutgoing,
                             isEditable: isOutgoing,
                             canBeRepliedTo: true,
                             isThreaded: false,
                             sender: .init(id: senderId),
                             content: .init(body: text))
    }
    
    private static func itemWith(html: String, timestamp: String, isOutgoing: Bool, senderId: String) -> TextRoomTimelineItem {
        let builder = AttributedStringBuilder(cacheKey: "preview", mentionBuilder: MentionBuilder())
        let attributedString = builder.fromHTML(html)
        
        return TextRoomTimelineItem(id: .random,
                                    timestamp: timestamp,
                                    isOutgoing: isOutgoing,
                                    isEditable: isOutgoing,
                                    canBeRepliedTo: true,
                                    isThreaded: false,
                                    sender: .init(id: senderId),
                                    content: .init(body: "", formattedBody: attributedString))
    }
}
