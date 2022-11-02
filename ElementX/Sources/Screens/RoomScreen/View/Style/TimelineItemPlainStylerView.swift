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

struct TimelineItemPlainStylerView<Content: View>: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            header
            
            VStack(alignment: .leading, spacing: 4) {
                content()
                supplementaryViews
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if timelineItem.shouldShowSenderDetails {
            HStack {
                TimelineSenderAvatarView(timelineItem: timelineItem)
                Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
                    .font(.body)
                    .foregroundColor(.element.primaryContent)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Text(timelineItem.timestamp)
                    .foregroundColor(Color.element.tertiaryContent)
                    .font(.element.caption2)
            }
        }
    }
    
    @ViewBuilder
    private var supplementaryViews: some View {
        VStack {
            if timelineItem.properties.isEdited {
                Text(ElementL10n.editedSuffix)
                    .font(.element.footnote)
                    .foregroundColor(.element.tertiaryContent)
            }
            
            if !timelineItem.properties.reactions.isEmpty {
                TimelineReactionsView(reactions: timelineItem.properties.reactions,
                                      alignment: .leading) { key in
                    context.send(viewAction: .sendReaction(key: key, eventID: timelineItem.id))
                }
            }
        }
    }
}

struct TimelineItemPlainStylerView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading) {
            ForEach(1..<MockRoomTimelineController().timelineItems.count, id: \.self) { index in
                let item = MockRoomTimelineController().timelineItems[index]
                RoomTimelineViewFactory().buildTimelineViewFor(timelineItem: item)
            }
        }
        .timelineStyle(.plain)
        .padding(.horizontal, 8)
        .previewLayout(.sizeThatFits)
    }
}
