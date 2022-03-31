//
//  NoticeRoomTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct NoticeRoomTimelineView: View {
    let timelineItem: NoticeRoomTimelineItem
    
    var body: some View {
        VStack(alignment: .leading) {
            EventBasedTimelineView(timelineItem: timelineItem)
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.bubble").padding(.top, 2.0)
                if let attributedComponents = timelineItem.attributedComponents {
                    FormattedBodyText(attributedComponents: attributedComponents)
                } else {
                    Text(timelineItem.text)
                }
            }
        }
        .id(timelineItem.id)
    }
}

struct NoticeRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            let timelineItem = NoticeRoomTimelineItem(id: UUID().uuidString,
                                                      text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                      timestamp: "Now",
                                                      shouldShowSenderDetails: true,
                                                      senderId: "Bob")
            NoticeRoomTimelineView(timelineItem: timelineItem)
            
            let timelineItem = NoticeRoomTimelineItem(id: UUID().uuidString,
                                                      text: "Some other text",
                                                      timestamp: "Later",
                                                      shouldShowSenderDetails: true,
                                                      senderId: "Anne")
            NoticeRoomTimelineView(timelineItem: timelineItem)
        }
        .padding()
    }
}
