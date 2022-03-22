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
            
            if let htmlString = buildHtmlString() {
                Text(AttributedString(htmlString))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if let attributedString = try? AttributedString(markdown: timelineItem.body) {
                    Text(attributedString)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(timelineItem.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .id(timelineItem.id)
    }
    
    private func buildHtmlString() -> NSAttributedString? {
        guard let formattedText = timelineItem.htmlBody,
              let encodedData = formattedText.data(using: String.Encoding.utf8) else {
            return nil
              }
        
        do {
            return try NSAttributedString(data: encodedData, options: [
                NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                NSAttributedString.DocumentReadingOptionKey.characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
            ], documentAttributes: nil)
        } catch {
            return nil
        }
    }
}

struct TextRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20.0) {
            let timelineItem = TextRoomTimelineItem(id: UUID().uuidString,
                                                    body: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                                    timestamp: "Now",
                                                    shouldShowSenderDetails: true,
                                                    senderId: "Bob")
            TextRoomTimelineView(timelineItem: timelineItem)
            
            let timelineItem = TextRoomTimelineItem(id: UUID().uuidString,
                                                    body: "Some other text",
                                                    timestamp: "Later",
                                                    shouldShowSenderDetails: true,
                                                    senderId: "Anne")
            TextRoomTimelineView(timelineItem: timelineItem)
        }
        .padding()
    }
}
