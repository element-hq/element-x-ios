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
    private let groupedViewStates: [RoomTimelineItemViewState]
    
    @State private var isExpanded = false
    
    init(timelineItem: CollapsibleTimelineItem) {
        self.timelineItem = timelineItem
        groupedViewStates = timelineItem.items.map { .init(item: $0, groupStyle: .single) }
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            Button {
                withElementAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Text(L10n.screenRoomTimelineStateChanges(timelineItem.items.count))
                    Text(Image(systemName: "chevron.forward"))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.elementDefault, value: isExpanded)
                }
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                .padding(.horizontal, 36.0)
                .padding(.vertical, 12.0)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 8.0)
            
            if isExpanded {
                ForEach(groupedViewStates) { viewState in
                    RoomTimelineItemView(viewState: viewState)
                }
            }
        }
    }
}

struct CollapsibleRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let item = CollapsibleTimelineItem(items: [
        SeparatorRoomTimelineItem(id: .init(timelineID: "First separator"), text: "This is a separator"),
        SeparatorRoomTimelineItem(id: .init(timelineID: "Second separator"), text: "This is another separator")
    ])
    
    static var previews: some View {
        CollapsibleRoomTimelineView(timelineItem: item)
    }
}
