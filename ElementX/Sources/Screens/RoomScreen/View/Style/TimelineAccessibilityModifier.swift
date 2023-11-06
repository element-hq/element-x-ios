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

private struct TimelineAccessibilityModifier: ViewModifier {
    let timelineItem: RoomTimelineItemProtocol
    
    @ViewBuilder
    func body(content: Content) -> some View {
        switch timelineItem {
        case is PollRoomTimelineItem, is VoiceMessageRoomTimelineItem:
            content
        case let timelineItem as EventBasedTimelineItemProtocol:
            content
                .accessibilityRepresentation {
                    VStack {
                        Text(timelineItem.sender.displayName ?? timelineItem.sender.id)
                        content
                    }
                }
                .accessibilityElement(children: .combine)
        default:
            content
                .accessibilityElement(children: .combine)
        }
    }
}

extension View {
    func timelineAccessibility(_ timelineItem: RoomTimelineItemProtocol) -> some View {
        modifier(TimelineAccessibilityModifier(timelineItem: timelineItem))
    }
}
