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
            EventBasedTimelineView(timelineItem: timelineItem)
            HStack(alignment: .top) {
                Image(systemName: "face.dashed").padding(.top, 1.0)
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

struct EmoteRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            let timelineItem = EmoteRoomTimelineItem(id: UUID().uuidString,
                                                     text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                     timestamp: "Now",
                                                     shouldShowSenderDetails: true,
                                                     senderId: "Bob")
            EmoteRoomTimelineView(timelineItem: timelineItem)
            
            let timelineItem = EmoteRoomTimelineItem(id: UUID().uuidString,
                                                     text: "Some other text",
                                                     timestamp: "Later",
                                                     shouldShowSenderDetails: true,
                                                     senderId: "Anne")
            EmoteRoomTimelineView(timelineItem: timelineItem)
        }
    }
}
