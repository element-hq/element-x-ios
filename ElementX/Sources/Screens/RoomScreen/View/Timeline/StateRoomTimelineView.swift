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
        Text(timelineItem.body)
            .font(.compound.bodySM)
            .multilineTextAlignment(.center)
            .foregroundColor(.element.secondaryContent)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 36.0)
            .padding(.vertical, 8.0)
    }
}

struct StateRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
    }
    
    static var body: some View {
        StateRoomTimelineView(timelineItem: item)
    }
    
    static let item = StateRoomTimelineItem(id: UUID().uuidString,
                                            body: "Alice joined",
                                            timestamp: "Now",
                                            isOutgoing: false,
                                            isEditable: false,
                                            sender: .init(id: ""))
}
