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
            if timelineItem.shouldShowSenderDetails {
                HStack {
                    avatar
                    Text(timelineItem.sender)
                        .font(.footnote)
                        .bold()
                    Spacer()
                    Text(timelineItem.timestamp)
                        .font(.footnote)
                }
                Divider()
            }
            Text(timelineItem.text)
        }
        .id(timelineItem.id)
    }
    
    @ViewBuilder var avatar: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color(.sRGB, red: 0.05, green: 0.74, blue: 0.55, opacity: 1.0))
            if let avatar = timelineItem.senderAvatar {
                Image(uiImage: avatar)
                    .resizable()
                    .clipShape(Circle())
            } else {
                Text(timelineItem.sender.prefix(2).suffix(1))
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
            }
        }
        .frame(width: 44.0, height: 44.0)
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
