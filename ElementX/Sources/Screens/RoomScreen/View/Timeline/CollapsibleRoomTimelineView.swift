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
    private let timelineViewModels: [RoomTimelineItemViewModel]
    
    @State private var isExpanded = false

    init(timelineItem: CollapsibleTimelineItem) {
        self.timelineItem = timelineItem
        timelineViewModels = timelineItem.items.map { .init(item: $0, groupStyle: .single) }
    }
    
    var body: some View {
        DisclosureGroup(L10n.roomTimelineStateChanges(timelineItem.items.count), isExpanded: $isExpanded) {
            Group {
                ForEach(timelineViewModels) { viewModel in
                    RoomTimelineItemView(viewModel: viewModel)
                }
            }.transition(.opacity.animation(.elementDefault))
        }
        .disclosureGroupStyle(CollapsibleRoomTimelineItemDisclosureGroupStyle())
        .transaction { transaction in
            transaction.animation = .noAnimation // Fixes weird animations on the disclosure indicator
        }
    }
}

private struct CollapsibleRoomTimelineItemDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0.0) {
            Button { configuration.isExpanded.toggle() } label: {
                HStack(alignment: .center) {
                    configuration.label
                    Text(Image(systemName: "chevron.forward"))
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .animation(.elementDefault, value: configuration.isExpanded)
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
            
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

struct CollapsibleRoomTimelineView_Previews: PreviewProvider {
    static let item = CollapsibleTimelineItem(items: [
        SeparatorRoomTimelineItem(id: "First separator", text: "This is a separator"),
        SeparatorRoomTimelineItem(id: "Second separator", text: "This is another separator")
    ])
    
    static var previews: some View {
        CollapsibleRoomTimelineView(timelineItem: item)
    }
}
