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
    static let viewModel = RoomScreenViewModel.mock
    
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
