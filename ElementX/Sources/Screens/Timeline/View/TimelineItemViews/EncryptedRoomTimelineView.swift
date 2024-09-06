//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EncryptedRoomTimelineView: View {
    let timelineItem: EncryptedRoomTimelineItem
    
    var icon: KeyPath<CompoundIcons, Image> {
        switch timelineItem.encryptionType {
        case .megolmV1AesSha2(_, let cause):
            switch cause {
            case .unknown:
                return \.time
            case .membership:
                return \.block
            }
        default:
            return \.time
        }
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Label(timelineItem.body, icon: icon, iconSize: .small, relativeTo: .compound.bodyLG)
                .labelStyle(RoomTimelineViewLabelStyle())
                .font(.compound.bodyLG)
        }
    }
}

struct RoomTimelineViewLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
                .foregroundColor(.compound.iconSecondary)
            configuration.title
                .foregroundColor(.compound.textPrimary)
        }
        .padding(.horizontal, 4)
    }
}

struct EncryptedRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EncryptedRoomTimelineView(timelineItem: itemWith(text: L10n.commonWaitingForDecryptionKey,
                                                             timestamp: "Now",
                                                             isOutgoing: false,
                                                             senderId: "Bob"))
            
            EncryptedRoomTimelineView(timelineItem: itemWith(text: L10n.commonWaitingForDecryptionKey,
                                                             timestamp: "Later",
                                                             isOutgoing: true,
                                                             senderId: "Anne"))
            
            EncryptedRoomTimelineView(timelineItem: itemWith(text: "Some other text that is very long and will wrap onto multiple lines.",
                                                             timestamp: "Later",
                                                             isOutgoing: true,
                                                             senderId: "Anne"))
            
            EncryptedRoomTimelineView(timelineItem: expectedItemWith(timestamp: "Now",
                                                                     isOutgoing: false,
                                                                     senderId: "Bob"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, isOutgoing: Bool, senderId: String) -> EncryptedRoomTimelineItem {
        EncryptedRoomTimelineItem(id: .random,
                                  body: text,
                                  encryptionType: .unknown,
                                  timestamp: timestamp,
                                  isOutgoing: isOutgoing,
                                  isEditable: false,
                                  canBeRepliedTo: false,
                                  sender: .init(id: senderId))
    }
    
    private static func expectedItemWith(timestamp: String, isOutgoing: Bool, senderId: String) -> EncryptedRoomTimelineItem {
        EncryptedRoomTimelineItem(id: .random,
                                  body: L10n.commonUnableToDecryptNoAccess,
                                  encryptionType: .megolmV1AesSha2(sessionID: "foo", cause: .membership),
                                  timestamp: timestamp,
                                  isOutgoing: isOutgoing,
                                  isEditable: false,
                                  canBeRepliedTo: false,
                                  sender: .init(id: senderId))
    }
}
