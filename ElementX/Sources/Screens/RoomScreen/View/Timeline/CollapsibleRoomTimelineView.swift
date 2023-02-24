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

struct CollapsibleRoomTimelineView: View {
    private let timelineItem: CollapsibleTimelineItem
    private let timelineViews: [RoomTimelineViewProvider]
    
    @State private var isExpanded = false

    init(timelineItem: CollapsibleTimelineItem) {
        self.timelineItem = timelineItem
        timelineViews = timelineItem.items.map { RoomTimelineViewProvider(timelineItem: $0, groupStyle: .single) }
    }
    
    var body: some View {
        DisclosureGroup(ElementL10n.roomTimelineStateChanges(timelineItem.items.count),
                        isExpanded: $isExpanded) {
            Group {
                ForEach(timelineViews) { timelineView in
                    timelineView.body
                }
            }.transition(.opacity.animation(.elementDefault))
        }
        .disclosureGroupStyle(CollapsibleRoomTimelineItemDisclosureGroupStyle())
        .transaction { transaction in
            transaction.animation = .noAnimation // Fixes weird animations on the disclosure indicator
        }
    }
}

struct CollapsibleRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let item = CollapsibleTimelineItem(items: [SeparatorRoomTimelineItem(text: "This is a separator"),
                                                   SeparatorRoomTimelineItem(text: "This is another separator")])
        CollapsibleRoomTimelineView(timelineItem: item)
    }
}

private struct CollapsibleRoomTimelineItemDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack(alignment: .center) {
                configuration.label
                Text(Image(systemName: "chevron.forward"))
                    .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                    .animation(.elementDefault, value: configuration.isExpanded)
            }
            .frame(maxWidth: .infinity)
            .font(.element.footnote)
            .foregroundColor(.element.secondaryContent)
            .padding(.horizontal, 36)
            .padding(.vertical, 8)
            .onTapGesture {
                configuration.isExpanded.toggle()
            }
            
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
