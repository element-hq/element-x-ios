//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct AudioRoomTimelineView: View {
    let timelineItem: AudioRoomTimelineItem

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Label(title: { Text(timelineItem.body) },
                  icon: { Image(systemName: "waveform")
                      .foregroundColor(.compound.iconPrimary)
                  })
                  .labelStyle(RoomTimelineViewLabelStyle())
                  .font(.compound.bodyLG)
                  .padding(.vertical, 12)
                  .padding(.horizontal, 6)
                  .accessibilityLabel(L10n.commonAudio)
        }
    }
}

struct AudioRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        AudioRoomTimelineView(timelineItem: AudioRoomTimelineItem(id: .random,
                                                                  timestamp: "Now",
                                                                  isOutgoing: false,
                                                                  isEditable: false,
                                                                  canBeRepliedTo: true,
                                                                  isThreaded: false,
                                                                  sender: .init(id: "Bob"),
                                                                  content: .init(body: "audio.ogg", duration: 300, waveform: nil, source: nil, contentType: nil)))
    }
}
