//
// Copyright 2023 New Vector Ltd
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

struct StateRoomTimelineView: View {
    let timelineItem: StateRoomTimelineItem
    
    var body: some View {
        Text(timelineItem.text)
    }
}

struct StateRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
    }
    
    static var body: some View {
        let item = StateRoomTimelineItem(id: UUID().uuidString, text: "Alice joined", timestamp: "Now", groupState: .beginning, isOutgoing: false, isEditable: false, senderId: "")
        return StateRoomTimelineView(timelineItem: item)
    }
}
