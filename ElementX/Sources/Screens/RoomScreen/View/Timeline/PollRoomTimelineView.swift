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

struct PollRoomTimelineView: View {
    let timelineItem: PollRoomTimelineItem
    @Environment(\.timelineStyle) var timelineStyle

    var body: some View {
        Text("Hello World")
    }
}

struct PollRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob")))
    }
}
