//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct AudioRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: AudioRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            MediaFileRoomTimelineContent(filename: timelineItem.content.filename,
                                         fileSize: timelineItem.content.fileSize,
                                         caption: timelineItem.content.caption,
                                         formattedCaption: timelineItem.content.formattedCaption,
                                         additionalWhitespaces: timelineItem.additionalWhitespaces(),
                                         isAudioFile: true) {
                context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
            }
            .accessibilityLabel(L10n.commonAudio)
        }
    }
}

struct AudioRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        VStack(spacing: 20) {
            AudioRoomTimelineView(timelineItem: makeItem(filename: "audio.ogg",
                                                         fileSize: 2 * 1024 * 1024))
            
            AudioRoomTimelineView(timelineItem: makeItem(filename: "Best Song Ever.mp3",
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
