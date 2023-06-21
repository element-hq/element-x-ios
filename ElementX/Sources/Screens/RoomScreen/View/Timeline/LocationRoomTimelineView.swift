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

struct LocationRoomTimelineView: View {
    let timelineItem: LocationRoomTimelineItem
    @Environment(\.timelineStyle) var timelineStyle

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Text(timelineItem.body)
                .background(Color.red)
        }
    }
}

struct LocationRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        #warning("AG: fix me")
        return EmptyView()
        // LocationRoomTimelineView(timelineItem: )
    }
}
