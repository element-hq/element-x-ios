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
            if let attributedString = try? AttributedString(markdown: timelineItem.text) {
                Text(attributedString)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(timelineItem.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .id(timelineItem.id)
    }
}

struct TextRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20.0) {
            let timelineItem = TextRoomTimelineItem(id: UUID().uuidString,
                                                    text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                    timestamp: "Now",
                                                    shouldShowSenderDetails: true,
                                                    sender: "Bob")
            TextRoomTimelineView(timelineItem: timelineItem)
            
            let timelineItem = TextRoomTimelineItem(id: UUID().uuidString,
                                                    text: "Some other text",
                                                    timestamp: "Later",
                                                    shouldShowSenderDetails: true,
                                                    sender: "Anne")
            TextRoomTimelineView(timelineItem: timelineItem)
        }
        .padding()
    }
}
