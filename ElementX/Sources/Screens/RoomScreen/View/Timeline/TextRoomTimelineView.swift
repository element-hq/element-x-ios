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
        VStack(alignment: .leading) {
            EventBasedTimelineView(timelineItem: timelineItem)
            if let attributedComponents = timelineItem.attributedComponents {
                FormattedBodyText(attributedComponents: attributedComponents)
            } else {
                Text(timelineItem.text)
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
            let timelineItem = TextRoomTimelineItem(id: UUID().uuidString,
                                                    text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                    timestamp: "Now",
                                                    shouldShowSenderDetails: true,
                                                    senderId: "Bob")
            TextRoomTimelineView(timelineItem: timelineItem)
            
            let timelineItem = TextRoomTimelineItem(id: UUID().uuidString,
                                                    text: "Some other text",
                                                    timestamp: "Later",
                                                    shouldShowSenderDetails: true,
                                                    senderId: "Anne")
            TextRoomTimelineView(timelineItem: timelineItem)
        }
    }
}
