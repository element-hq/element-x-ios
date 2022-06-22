//
//  EventBasedTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct EventBasedTimelineView: View {
    let timelineItem: EventBasedTimelineItemProtocol
    
    var body: some View {
        if timelineItem.shouldShowSenderDetails {
            Spacer()
            HStack(alignment: .top, spacing: 4) {
                avatar
                Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
                    .font(.body)
                    .bold()
            }
        }
    }
    
    @ViewBuilder private var avatar: some View {
        ZStack(alignment: .center) {
            if let avatar = timelineItem.senderAvatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .overlay(Circle().stroke(Color.element.accent))
            } else {
                PlaceholderAvatarImage(firstCharacter: String(firstLetter))
            }
        }
        .clipShape(Circle())
        .frame(width: 24.0, height: 24.0)
        .animation(.default, value: timelineItem.senderAvatar)
    }
    
    private var firstLetter: String {
        if let senderDisplayName = timelineItem.senderDisplayName {
            return senderDisplayName.prefix(1).uppercased()
        } else {
            return timelineItem.senderId.prefix(2).suffix(1).uppercased()
        }
    }
}

struct EventBasedTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EventBasedTimelineView(timelineItem: itemWith(text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                         timestamp: "Now",
                                                         senderId: "Bob"))
            
            EventBasedTimelineView(timelineItem: itemWith(text: "Some other text",
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
