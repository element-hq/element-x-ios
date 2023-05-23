//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftUI

struct TextRoomTimelineView: View {
    let timelineItem: TextRoomTimelineItem
    @Environment(\.timelineStyle) private var timelineStyle

    // These is needed to create the slightly off inlined timestamp effect
    private var untrimmableEnd: String {
        guard timelineStyle == .bubbles else {
            return ""
        }
        var whiteSpaces = ""
        timelineItem.timestampString.forEach { _ in
            // fixed size whitespace of size 1/3 em per character
            whiteSpaces += "\u{2004}"
        }
        // To account for the extra spacing created by the alert icon
        if timelineItem.properties.deliveryStatus == .sendingFailed {
            whiteSpaces += String(repeating: "\u{2004}", count: 5)
        }
        // braille whitespace, which is non breakable but makes previous whitespaces breakable
        return whiteSpaces + "\u{2800}"
    }

    private var attributedString: AttributedString? {
        guard var attributedString = timelineItem.content.formattedBody else {
            return nil
        }
        let untrimmableEnd = AttributedString(untrimmableEnd)
        attributedString.insert(untrimmableEnd, at: attributedString.endIndex)
        return attributedString
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if let attributedString {
                FormattedBodyText(attributedString: attributedString)
            } else {
                let body = timelineItem.content.body + untrimmableEnd
                FormattedBodyText(text: body)
            }
        }
    }
}

struct TextRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        body.timelineStyle(.plain).environmentObject(viewModel.context)
    }
    
    static var body: some View {
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
        }
    }
    
    private static func itemWith(text: String, timestamp: String, isOutgoing: Bool, senderId: String) -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: UUID().uuidString,
                             timestamp: timestamp,
                             isOutgoing: isOutgoing,
                             isEditable: isOutgoing,
                             sender: .init(id: senderId),
                             content: .init(body: text))
    }
}
