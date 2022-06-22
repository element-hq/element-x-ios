//
//  TextRoomTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct TextRoomTimelineView: View {
    let timelineItem: TextRoomTimelineItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            EventBasedTimelineView(timelineItem: timelineItem)
            TimelineItemStylerView(timelineItem: timelineItem) {
                if let attributedComponents = timelineItem.attributedComponents {
                    FormattedBodyText(attributedComponents: attributedComponents)
                } else {
                    Text(timelineItem.text)
                        .font(.body)
                }
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
                                                        senderId: "Bob"))
            
            TextRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                        timestamp: "Later",
                                                        senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, senderId: String) -> TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                     text: text,
                                     timestamp: timestamp,
                                     shouldShowSenderDetails: true,
                                     senderId: senderId)
    }
}
