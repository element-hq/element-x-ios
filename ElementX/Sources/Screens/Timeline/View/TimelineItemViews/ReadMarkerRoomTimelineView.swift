//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct ReadMarkerRoomTimelineView: View {
    let timelineItem: ReadMarkerRoomTimelineItem
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(L10n.screenRoomTimelineReadMarkerTitle)
                .textCase(.uppercase)
                .font(.compound.bodyXSSemibold)
                .foregroundColor(.compound.textSecondary)
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.compound.borderInteractivePrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct ReadMarkerRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock

    static let item = ReadMarkerRoomTimelineItem(id: .init(timelineID: .init(UUID().uuidString)))

    static var previews: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoomTimelineItemView(viewState: .init(type: .separator(.init(id: .init(timelineID: "Separator"), text: "Today")), groupStyle: .single))
            RoomTimelineItemView(viewState: .init(type: .text(.init(id: .init(timelineID: ""),
                                                                    timestamp: "",
                                                                    isOutgoing: true,
                                                                    isEditable: false,
                                                                    canBeRepliedTo: true,
                                                                    isThreaded: false,
                                                                    sender: .init(id: "1", displayName: "Bob"),
                                                                    content: .init(body: "This is another message"))), groupStyle: .single))

            ReadMarkerRoomTimelineView(timelineItem: item)

            RoomTimelineItemView(viewState: .init(type: .separator(.init(id: .init(timelineID: "Separator"), text: "Today")), groupStyle: .single))
            RoomTimelineItemView(viewState: .init(type: .text(.init(id: .init(timelineID: ""),
                                                                    timestamp: "",
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    canBeRepliedTo: true,
                                                                    isThreaded: false,
                                                                    sender: .init(id: "", displayName: "Alice"),
                                                                    content: .init(body: "This is a message"))), groupStyle: .single))
        }
        .environmentObject(viewModel.context)
    }
}
