//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct FileMediaEventsTimelineView: View {
    let timelineItem: FileRoomTimelineItem
    
    var body: some View {
        MediaFileRoomTimelineContent(filename: timelineItem.content.filename,
                                     fileSize: timelineItem.content.fileSize,
                                     caption: timelineItem.content.caption,
                                     formattedCaption: timelineItem.content.formattedCaption,
                                     additionalWhitespaces: timelineItem.additionalWhitespaces())
            .accessibilityLabel(L10n.commonFile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bubbleBackground(isOutgoing: timelineItem.isOutgoing)
    }
}

struct FileMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        VStack(spacing: 20.0) {
            FileMediaEventsTimelineView(timelineItem: makeItem(filename: "document.pdf"))
            
            FileMediaEventsTimelineView(timelineItem: makeItem(filename: "document.pdf",
                                                               fileSize: 3 * 1024 * 1024))
            
            FileMediaEventsTimelineView(timelineItem: makeItem(filename: "spreadsheet.xlsx",
                                                               fileSize: 17 * 1024,
                                                               caption: "The important figures you asked me to send over."))
            
            FileMediaEventsTimelineView(timelineItem: makeItem(filename: "document.txt",
                                                               fileSize: 456,
                                                               caption: "Plain caption",
                                                               formattedCaption: "Formatted caption"))
        }
        .environmentObject(viewModel.context)
    }
    
    static func makeItem(filename: String,
                         fileSize: UInt? = nil,
                         caption: String? = nil,
                         formattedCaption: AttributedString? = nil) -> FileRoomTimelineItem {
        .init(id: .randomEvent,
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              isThreaded: false,
              sender: .init(id: "Bob"),
              content: .init(filename: filename,
                             caption: caption,
                             formattedCaption: formattedCaption,
                             source: nil,
                             fileSize: fileSize,
                             thumbnailSource: nil,
                             contentType: nil))
    }
}
