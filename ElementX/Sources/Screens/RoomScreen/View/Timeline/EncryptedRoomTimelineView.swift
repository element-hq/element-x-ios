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

import SwiftUI

struct EncryptedRoomTimelineView: View {
    let timelineItem: EncryptedRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Label {
                FormattedBodyText(text: timelineItem.text)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundColor(.element.secondaryContent)
            }
            .labelStyle(RoomTimelineViewLabelStyle())
        }
    }
}

struct RoomTimelineViewLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

struct EncryptedRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        body.timelineStyle(.plain).environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EncryptedRoomTimelineView(timelineItem: itemWith(text: "Text",
                                                             timestamp: "Now",
                                                             isOutgoing: false,
                                                             senderId: "Bob"))
            
            EncryptedRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                             timestamp: "Later",
                                                             isOutgoing: true,
                                                             senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, isOutgoing: Bool, senderId: String) -> EncryptedRoomTimelineItem {
        EncryptedRoomTimelineItem(id: UUID().uuidString,
                                  text: text,
                                  encryptionType: .unknown,
                                  timestamp: timestamp,
                                  groupState: .single,
                                  isOutgoing: isOutgoing,
                                  isEditable: false,
                                  sender: .init(id: senderId))
    }
}
