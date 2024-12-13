//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct AudioMediaEventsTimelineView: View {
    let timelineItem: AudioRoomTimelineItem
    
    var body: some View {
        MediaFileRoomTimelineContent(filename: timelineItem.content.filename,
                                     fileSize: timelineItem.content.fileSize,
                                     caption: timelineItem.content.caption,
                                     formattedCaption: timelineItem.content.formattedCaption,
                                     additionalWhitespaces: timelineItem.additionalWhitespaces(),
                                     isAudioFile: true)
            .accessibilityLabel(L10n.commonAudio)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bubbleBackground(isOutgoing: timelineItem.isOutgoing)
    }
}

struct AudioMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        VStack(spacing: 20) {
            AudioMediaEventsTimelineView(timelineItem: makeItem(filename: "audio.ogg",
                                                                fileSize: 2 * 1024 * 1024))
            
            AudioMediaEventsTimelineView(timelineItem: makeItem(filename: "Best Song Ever.mp3",
                                                                fileSize: 7 * 1024 * 1024,
                                                                caption: "This song rocks!"))
        }
        .environmentObject(viewModel.context)
    }
    
    static func makeItem(filename: String, fileSize: UInt, caption: String? = nil) -> AudioRoomTimelineItem {
        .init(id: .randomEvent,
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              isThreaded: false,
              sender: .init(id: "Bob"),
              content: .init(filename: filename,
                             caption: caption,
                             duration: 300,
                             waveform: nil,
                             source: nil,
                             fileSize: fileSize,
                             contentType: nil))
    }
}
