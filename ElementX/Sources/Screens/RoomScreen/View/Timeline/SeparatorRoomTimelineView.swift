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

struct SeparatorRoomTimelineView: View {
    let timelineItem: SeparatorRoomTimelineItem
    
    var body: some View {
        LabelledDivider(label: timelineItem.text)
            .id(timelineItem.id)
            .padding(.vertical, 8)
    }
}

struct LabelledDivider: View {
    let label: String
    let color: Color

    init(label: String, color: Color = Color.element.secondaryContent) {
        self.label = label
        self.color = color
    }

    var body: some View {
        HStack {
            line
            Text(label)
                .foregroundColor(color)
                .fixedSize()
            line
        }
    }

    var line: some View {
        VStack { Divider().background(color) }
    }
}

struct SeparatorRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let item = SeparatorRoomTimelineItem(id: UUID().uuidString, text: "This is a separator")
        SeparatorRoomTimelineView(timelineItem: item)
    }
}
