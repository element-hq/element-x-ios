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

struct ReadMarkerRoomTimelineView: View {
    let timelineItem: ReadMarkerRoomTimelineItem
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(L10n.roomTimelineReadMarkerTitle)
                .textCase(.uppercase)
                .font(.element.caption2Bold)
                .foregroundColor(.element.quaternaryContent)
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.element.quaternaryContent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct ReadMarkerRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static let item = ReadMarkerRoomTimelineItem()
    static var previews: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoomTimelineViewProvider.separator(.init(text: "Today"), .single)
            RoomTimelineViewProvider.text(.init(id: "",
                                                body: "This is another message",
                                                timestamp: "",
                                                isOutgoing: true,
                                                isEditable: false,
                                                sender: .init(id: "1", displayName: "Bob")), .single)
            
            ReadMarkerRoomTimelineView(timelineItem: item)
            
            RoomTimelineViewProvider.separator(.init(text: "Today"), .single)
            RoomTimelineViewProvider.text(.init(id: "",
                                                body: "This is a message",
                                                timestamp: "",
                                                isOutgoing: false,
                                                isEditable: false,
                                                sender: .init(id: "", displayName: "Alice")), .single)
        }
        .padding(.horizontal, 8)
        .environmentObject(viewModel.context)
    }
}
