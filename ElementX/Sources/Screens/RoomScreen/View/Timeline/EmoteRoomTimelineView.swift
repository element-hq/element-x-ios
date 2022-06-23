//
//  EmoteRoomTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct EmoteRoomTimelineView: View {
    let timelineItem: EmoteRoomTimelineItem
    
    var body: some View {
        VStack(alignment: .leading) {
            TimelineItemStylerView(timelineItem: timelineItem) {
                EventBasedTimelineSenderView(timelineItem: timelineItem)
            } content: {
                HStack(alignment: .top) {
                    Image(systemName: "face.dashed").padding(.top, 1.0)
                    if let attributedComponents = timelineItem.attributedComponents {
                        FormattedBodyText(attributedComponents: attributedComponents)
                    } else {
                        Text(timelineItem.text)
                            .foregroundColor(.element.primaryContent)
                    }
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
        return EmoteRoomTimelineItem(id: UUID().uuidString,
                                     text: text,
                                     timestamp: timestamp,
                                     shouldShowSenderDetails: true,
                                     isOutgoing: false,
                                     senderId: senderId)
    }
}
